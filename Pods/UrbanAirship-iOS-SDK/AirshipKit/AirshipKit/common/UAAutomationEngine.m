/* Copyright 2018 Urban Airship and Contributors */

#import "UAAutomationEngine+Internal.h"
#import "UAAnalytics+Internal.h"
#import "UAAutomationStore+Internal.h"
#import "UAScheduleTriggerData+Internal.h"
#import "UAScheduleData+Internal.h"
#import "UAScheduleDelayData+Internal.h"
#import "UASchedule+Internal.h"
#import "UAScheduleTrigger+Internal.h"
#import "UAScheduleInfo+Internal.h"
#import "UAEvent.h"
#import "UARegionEvent+Internal.h"
#import "UACustomEvent+Internal.h"
#import "NSJSONSerialization+UAAdditions.h"
#import "UAJSONPredicate.h"
#import "UAGlobal.h"
#import "UAirship.h"
#import "UAApplicationMetrics.h"
#import "UAScheduleEdits+Internal.h"

@interface UAAutomationStateCondition : NSObject

@property (nonatomic, copy, nonnull) BOOL (^predicate)(void);
@property (nonatomic, copy, nonnull) id (^argumentGenerator)(void);
@property (nonatomic, strong, nonnull) NSDate *stateChangeDate;

- (instancetype)initWithPredicate:(BOOL (^_Nonnull)(void))predicate argumentGenerator:(id (^)(void))argumentGenerator;

@end

@implementation UAAutomationStateCondition

- (instancetype)initWithPredicate:(BOOL (^_Nonnull)(void))predicate argumentGenerator:(id (^)(void))argumentGenerator {
    self = [super init];
    if (self) {
        self.predicate = predicate;
        self.argumentGenerator = argumentGenerator;
        self.stateChangeDate = [NSDate date];
    }
    return self;
}

@end

@interface UAAutomationEngine()
@property (nonatomic, strong) UATimerScheduler *timerScheduler;
@property (nonatomic, copy) NSString *currentScreen;
@property (nonatomic, copy, nullable) NSString * currentRegion;
@property (nonatomic, assign) BOOL isForegrounded;
@property (nonatomic, assign) BOOL isBackgrounded;
@property (nonatomic, strong) NSMutableArray *activeTimers;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (nonatomic, assign) BOOL isStarted;
@property (nonnull, strong) NSMutableDictionary *stateConditions;
@property (nonnull, strong) NSNotificationCenter *notificationCenter;

@property (atomic, assign) BOOL paused;
@end

@implementation UAAutomationEngine

- (void)dealloc {
    [self stop];
    [self.automationStore shutDown];
}


- (instancetype)initWithAutomationStore:(UAAutomationStore *)automationStore timerScheduler:(UATimerScheduler *)timerScheduler notificationCenter:(NSNotificationCenter *)notificationCenter {
    self = [super init];

    if (self) {
        self.automationStore = automationStore;
        self.timerScheduler = timerScheduler;
        self.activeTimers = [NSMutableArray array];
        self.isForegrounded = [UIApplication sharedApplication].applicationState == UIApplicationStateActive;
        self.isBackgrounded = [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
        self.stateConditions = [NSMutableDictionary dictionary];
        self.paused = NO;
        self.notificationCenter = notificationCenter;
    }

    return self;
}

+ (instancetype)automationEngineWithAutomationStore:(UAAutomationStore *)automationStore timerScheduler:(UATimerScheduler *)timerScheduler notificationCenter:(NSNotificationCenter *)notificationCenter{
    return [[UAAutomationEngine alloc] initWithAutomationStore:automationStore timerScheduler:timerScheduler notificationCenter:notificationCenter];
}

+ (instancetype)automationEngineWithAutomationStore:(UAAutomationStore *)automationStore {
    return [[UAAutomationEngine alloc] initWithAutomationStore:automationStore timerScheduler:[[UATimerScheduler alloc] init] notificationCenter:[NSNotificationCenter defaultCenter]];
}

#pragma mark -
#pragma mark Public API

- (void)start {
    if (self.isStarted) {
        return;
    }

    [self.notificationCenter addObserver:self
                                selector:@selector(enterBackground)
                                    name:UIApplicationDidEnterBackgroundNotification
                                  object:nil];

    [self.notificationCenter addObserver:self
                                selector:@selector(didBecomeActive)
                                    name:UIApplicationDidBecomeActiveNotification
                                  object:nil];

    [self.notificationCenter addObserver:self
                                selector:@selector(customEventAdded:)
                                    name:UACustomEventAdded
                                  object:nil];

    [self.notificationCenter addObserver:self
                                selector:@selector(screenTracked:)
                                    name:UAScreenTracked
                                  object:nil];

    [self.notificationCenter addObserver:self
                                selector:@selector(regionEventAdded:)
                                    name:UARegionEventAdded
                                  object:nil];

    [self cleanSchedules];
    [self resetExecutingSchedules];
    [self rescheduleTimers];
    [self createStateConditions];
    [self restoreCompoundTriggers];
    [self updateTriggersWithType:UAScheduleTriggerAppInit argument:nil incrementAmount:1.0];
    [self scheduleConditionsChanged];

    self.isStarted = YES;
}

- (void)stop {
    if (!self.isStarted) {
        return;
    }

    [self cancelTimers];
    [self.notificationCenter removeObserver:self];
    [self.stateConditions removeAllObjects];
    self.isStarted = NO;
}

- (void)pause {
    if (!self.paused) {
        self.paused = YES;
    }
}

- (void)resume {
    if (self.paused) {
        self.paused = NO;
        if (!self.isStarted) {
            [self start];
        } else {
            [self scheduleConditionsChanged];
        }
    }
}
- (void)schedule:(UAScheduleInfo *)scheduleInfo completionHandler:(void (^)(UASchedule *))completionHandler {
    // Only allow valid schedules to be saved
    if (!scheduleInfo.isValid) {
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil);
            });
        }

        return;
    }

    [self cleanSchedules];

    // Create a schedule to save
    UASchedule *schedule = [UASchedule scheduleWithIdentifier:[NSUUID UUID].UUIDString info:scheduleInfo];

    // Try to save the schedule
    [self.automationStore saveSchedule:schedule completionHandler:^(BOOL success) {
        // If saving the schedule was successful, process any compound triggers
        if (success) {
            UA_WEAKIFY(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                UA_STRONGIFY(self);
                [self checkCompoundTriggerState:@[schedule]];
            });
        }
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(success ? schedule : nil);
            });
        }
    }];
}

- (void)scheduleMultiple:(NSArray<UAScheduleInfo *> *)scheduleInfos completionHandler:(void (^)(NSArray <UASchedule *> *))completionHandler {
    [self cleanSchedules];

    // Create schedules to save (only allow valid schedules)
    NSMutableArray<UASchedule *> *schedules = [NSMutableArray arrayWithCapacity:scheduleInfos.count];
    for (UAScheduleInfo *scheduleInfo in scheduleInfos) {
        if (scheduleInfo.isValid) {
            UASchedule *schedule = [UASchedule scheduleWithIdentifier:[NSUUID UUID].UUIDString info:scheduleInfo];
            [schedules addObject:schedule];
        }
    }

    if (!schedules.count) {
        // don't save if there are no schedules
        completionHandler(@[]);
        return;
    }

    // Try to save the schedules
    [self.automationStore saveSchedules:schedules completionHandler:^(BOOL success) {
        if (success) {
            UA_WEAKIFY(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                UA_STRONGIFY(self);
                [self checkCompoundTriggerState:schedules];
            });
        }

        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(schedules);
            });
        }
    }];
}

- (void)cancelScheduleWithID:(NSString *)identifier {
    [self.automationStore deleteSchedule:identifier];
    [self cancelTimersWithIdentifiers:[NSSet setWithArray:@[identifier]]];
}

- (void)cancelAll {
    [self.automationStore deleteAllSchedules];
    [self cancelTimers];
}

- (void)cancelSchedulesWithGroup:(NSString *)group {
    [self.automationStore deleteSchedules:group];
    [self cancelTimersWithGroup:group];
}

- (void)getScheduleWithID:(NSString *)identifier completionHandler:(void (^)(UASchedule *))completionHandler {
    UA_WEAKIFY(self)
    [self.automationStore getSchedule:identifier completionHandler:^(UAScheduleData *scheduleData) {
        UA_STRONGIFY(self)

        UASchedule *schedule = nil;
        if (scheduleData) {
            schedule = [self scheduleFromData:scheduleData];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(schedule);
        });
    }];
}

- (void)getSchedules:(void (^)(NSArray<UASchedule *> *))completionHandler {
    UA_WEAKIFY(self)
    [self.automationStore getSchedules:^(NSArray<UAScheduleData *> *schedulesData) {
        UA_STRONGIFY(self)

        NSMutableArray *schedules = [NSMutableArray array];
        for (UAScheduleData *scheduleData in schedulesData) {
            UASchedule *schedule = [self scheduleFromData:scheduleData];
            if (schedule) {
                [schedules addObject:schedule];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(schedules);
        });
    }];
}

- (void)getSchedulesWithGroup:(NSString *)group completionHandler:(void (^)(NSArray<UASchedule *> *))completionHandler {
    UA_WEAKIFY(self)
    [self.automationStore getSchedules:group completionHandler:^(NSArray<UAScheduleData *> *schedulesData) {
        UA_STRONGIFY(self)
        NSMutableArray *schedules = [NSMutableArray array];
        for (UAScheduleData *scheduleData in schedulesData) {
            UASchedule *schedule = [self scheduleFromData:scheduleData];
            if (schedule) {
                [schedules addObject:[self scheduleFromData:scheduleData]];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(schedules);
        });
    }];
}

- (void)editScheduleWithID:(NSString *)identifier
                     edits:(UAScheduleEdits *)edits
         completionHandler:(void (^)(UASchedule *))completionHandler {

    UA_WEAKIFY(self)
    [self.automationStore getSchedule:identifier completionHandler:^(UAScheduleData *scheduleData) {
        UA_STRONGIFY(self)

        UASchedule *schedule = nil;
        if (scheduleData) {
            [UAAutomationEngine applyEdits:edits toData:scheduleData];

            schedule = [self scheduleFromData:scheduleData];
            if (!schedule) {
                return completionHandler(nil);
            }

            BOOL overLimit = [scheduleData isOverLimit];
            BOOL isExpired = [scheduleData isExpired];

            // Check if the schedule needs to be rehabilitated or finished due to the edits
            if ([scheduleData.executionState unsignedIntegerValue] == UAScheduleStateFinished && !overLimit && !isExpired) {
                NSDate *finishDate = scheduleData.executionStateChangeDate;
                scheduleData.executionState = @(UAScheduleStateIdle);

                // Handle any state changes that might have been missed while the schedule was finished
                UA_WEAKIFY(self);
                dispatch_async(dispatch_get_main_queue(), ^{
                    UA_STRONGIFY(self);
                    [self checkCompoundTriggerState:@[schedule] forStateNewerThanDate:finishDate];
                });
            } else if ([scheduleData.executionState unsignedIntegerValue] != UAScheduleStateFinished && (overLimit || isExpired)) {
                scheduleData.executionState = @(UAScheduleStateFinished);
            }
        }

        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(schedule);
            });
        }
    }];
}

- (void)cleanSchedules {
    UA_WEAKIFY(self)
    // Expired schedules
    [self.automationStore getActiveExpiredSchedules:^(NSArray<UAScheduleData *> *schedulesData) {
        UA_STRONGIFY(self)
        for (UAScheduleData *scheduleData in schedulesData) {
            [self handleExpiredScheduleData:scheduleData];
        }
    }];

    // Finished schedules
    [self.automationStore getSchedulesWithStates:@[@(UAScheduleStateFinished)] completionHandler:^(NSArray<UAScheduleData *> *schedulesData) {
        for (UAScheduleData *scheduleData in schedulesData) {
            NSDate *finishDate = [scheduleData.executionStateChangeDate dateByAddingTimeInterval:[scheduleData.editGracePeriod doubleValue]];
            if ([finishDate compare:[NSDate date]] == NSOrderedAscending) {
                [scheduleData.managedObjectContext deleteObject:scheduleData];
            }
        }
    }];
}

#pragma mark -
#pragma mark Event listeners

- (void)didBecomeActive {
    if (!self.isForegrounded) {
        [self enterForeground];
    }
}

- (void)enterForeground {
    self.isForegrounded = YES;
    self.isBackgrounded = NO;

    if (!self.activeTimers) {
        [self rescheduleTimers];
    }

    // Update any dependent foreground triggers
    [self updateTriggersWithType:UAScheduleTriggerAppForeground argument:nil incrementAmount:1.0];

    // Active session triggers are also updated by foreground transitions
    [self updateTriggersWithType:UAScheduleTriggerActiveSession argument:nil incrementAmount:1.0];
    UAAutomationStateCondition *condition = self.stateConditions[@(UAScheduleTriggerActiveSession)];
    condition.stateChangeDate = [NSDate date];

    [self scheduleConditionsChanged];
}

- (void)enterBackground {
    if (!self.isBackgrounded) {
        self.isForegrounded = NO;
        self.isBackgrounded = YES;

        [self updateTriggersWithType:UAScheduleTriggerAppBackground argument:nil incrementAmount:1.0];
        [self scheduleConditionsChanged];
    }
}

-(void)customEventAdded:(NSNotification *)notification {
    UACustomEvent *event = notification.userInfo[UAEventKey];

    [self updateTriggersWithType:UAScheduleTriggerCustomEventCount
                        argument:event.payload
                 incrementAmount:1.0];

    if (event.eventValue) {
        [self updateTriggersWithType:UAScheduleTriggerCustomEventValue
                            argument:event.payload
                     incrementAmount:[event.eventValue doubleValue]];
    }
}

-(void)regionEventAdded:(NSNotification *)notification {
    UARegionEvent *event = notification.userInfo[UAEventKey];

    UAScheduleTriggerType triggerType;

    if (event.boundaryEvent == UABoundaryEventEnter) {
        triggerType = UAScheduleTriggerRegionEnter;
        self.currentRegion = event.regionID;
    } else {
        triggerType = UAScheduleTriggerRegionExit;
        self.currentRegion = nil;
    }

    [self updateTriggersWithType:triggerType argument:event.payload incrementAmount:1.0];

    [self scheduleConditionsChanged];
}

-(void)screenTracked:(NSNotification *)notification {
    NSString *screenName = notification.userInfo[UAScreenKey];

    if (screenName) {
        [self updateTriggersWithType:UAScheduleTriggerScreen argument:screenName incrementAmount:1.0];
    }

    self.currentScreen = screenName;
    [self scheduleConditionsChanged];
}

#pragma mark -
#pragma mark Event processing

- (NSArray<UAScheduleData *> *)sortedScheduleDataByPriority:(NSArray<UAScheduleData *> *)scheduleData {
    NSSortDescriptor *ascending = [[NSSortDescriptor alloc] initWithKey:@"priority" ascending:YES];
    return [scheduleData sortedArrayUsingDescriptors:@[ascending]];
}

- (NSArray<UASchedule *> *)sortedSchedulesByPriority:(NSArray<UASchedule *> *)schedules {
    NSSortDescriptor *ascending = [[NSSortDescriptor alloc] initWithKey:@"info.priority" ascending:YES];
    return [schedules sortedArrayUsingDescriptors:@[ascending]];
}

- (void)updateTriggersWithScheduleID:(NSString *)scheduleID
                                type:(UAScheduleTriggerType)triggerType
                            argument:(id)argument
                     incrementAmount:(double)amount {

    if (self.paused) {
        return;
    }

    UA_LDEBUG(@"Updating triggers with type: %ld", (long)triggerType);

    NSDate *start = [NSDate date];

    UA_WEAKIFY(self)
    [self.automationStore getActiveTriggers:scheduleID type:triggerType completionHandler:^(NSArray<UAScheduleTriggerData *> *triggers) {

        UA_STRONGIFY(self)

        // Capture what schedules need to be cancelled and executed in sets so we do not double process any schedules
        NSMutableSet *schedulesToCancel = [NSMutableSet set];
        NSMutableSet *schedulesToExecute = [NSMutableSet set];

        // Process triggers
        for (UAScheduleTriggerData *trigger in triggers) {
            UAJSONPredicate *predicate = [UAAutomationEngine predicateFromData:trigger.predicateData];
            if (predicate && argument) {
                if (![predicate evaluateObject:argument]) {
                    continue;
                }
            }

            trigger.goalProgress = @([trigger.goalProgress doubleValue] + amount);
            if ([trigger.goalProgress compare:trigger.goal] != NSOrderedAscending) {
                trigger.goalProgress = 0;

                // A delay associated with a trigger indicates its a cancellation trigger
                if (trigger.delay) {
                    [schedulesToCancel addObject:trigger.delay.schedule];
                    continue;
                }

                // Normal execution trigger. Only reexecute schedules that are not currently pending
                if (trigger.schedule) {
                    [schedulesToExecute addObject:trigger.schedule];
                }
            }
        }

        // Process all the schedules to execute
        [self processTriggeredSchedules:[schedulesToExecute allObjects]];

        // Process all the schedules to cancel
        for (UAScheduleData *scheduleData in schedulesToCancel) {
            UA_LTRACE(@"Pending automation schedule %@ execution canceled", scheduleData.identifier);
            scheduleData.executionState = @(UAScheduleStateIdle);
        }

        // Cancel timers
        if (schedulesToCancel.count) {
            NSSet *timersToCancel = [schedulesToCancel valueForKeyPath:@"identifier"];

            // Handle timers on the main queue
            UA_WEAKIFY(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                UA_STRONGIFY(self);
                [self cancelTimersWithIdentifiers:timersToCancel];
            });
        }

        NSTimeInterval executionTime = -[start timeIntervalSinceNow];
        UA_LTRACE(@"Automation execution time: %f seconds, triggers: %ld, triggered schedules: %ld", executionTime, (unsigned long)triggers.count, (unsigned long)schedulesToExecute.count);
    }];
}

- (void)updateTriggersWithType:(UAScheduleTriggerType)triggerType argument:(id)argument incrementAmount:(double)amount {
    [self updateTriggersWithScheduleID:nil type:triggerType argument:argument incrementAmount:amount];
}

/**
 * Starts a timer for the schedule.
 *
 * @param scheduleData The schedule's data.
 */
- (void)startTimerForSchedule:(UAScheduleData *)scheduleData
                 timeInterval:(NSTimeInterval)timeInterval
                     selector:(SEL)selector {

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setValue:scheduleData.identifier forKey:@"identifier"];
    [userInfo setValue:scheduleData.group forKey:@"group"];

    // NSTimer should set the time to .1 if 0 or less
    if (timeInterval <= 0) {
        timeInterval = .1;
    }

    NSTimer *timer = [NSTimer timerWithTimeInterval:timeInterval
                                             target:self
                                           selector:selector
                                           userInfo:userInfo
                                            repeats:NO];

    // Schedule the timer on the main queue
    UA_WEAKIFY(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        UA_STRONGIFY(self);
        // Make sure we have a background task identifier before starting the timer
        if (self.backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
            self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                UA_LTRACE(@"Automation background task expired. Cancelling timer alarm.");
                [self cancelTimers];
            }];

            // No background time. The timer will be rescheduled the next time the app is active
            if (self.backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
                UA_LTRACE(@"Unable to request background task for automation timer.");
                return;
            }
        }

        UA_LTRACE(@"Starting automation timer for %f seconds with user info %@", timeInterval, timer.userInfo);
        [self.timerScheduler scheduleTimer:timer];
        [self.activeTimers addObject:timer];
    });
}

- (void)finishTimer:(NSTimer *)timer {
    [timer invalidate];
    [self.activeTimers removeObject:timer];

    UA_WEAKIFY(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        UA_STRONGIFY(self);
        if (!self.activeTimers.count) {
            [self endBackgroundTask];
        }
    });
}

/**
 * Delay timer fired for a schedule. Method is called on the main queue.
 *
 * @param timer The timer.
 */
- (void)delayTimerFired:(NSTimer *)timer {
    // Called on the main queue
    UA_LTRACE(@"Automation delay timer fired: %@", timer.userInfo);

    NSString *identifier = timer.userInfo[@"identifier"];

    UA_WEAKIFY(self);
    [self.automationStore getSchedule:identifier completionHandler:^(UAScheduleData *scheduleData) {
        UA_STRONGIFY(self);

        // Verify we are still delayed
        if (!scheduleData || [scheduleData.executionState intValue] != UAScheduleStateTimeDelayed) {
            return;
        }

        // Check expired
        if ([scheduleData isExpired]) {
            [self handleExpiredScheduleData:scheduleData];
            return;
        }

        // Delay -> Prepare
        scheduleData.executionState = @(UAScheduleStatePreparingSchedule);
        [self prepareSchedules:@[scheduleData]];

        // Finish the timer
        [self finishTimer:timer];
    }];
}

/**
 * Interval timer fired for a schedule. Method is called on the main queue.
 *
 * @param timer The timer.
 */
- (void)intervalTimerFired:(NSTimer *)timer {
    UA_LTRACE(@"Automation interval timer fired: %@", timer.userInfo);

    NSString *identifier = timer.userInfo[@"identifier"];

    UA_WEAKIFY(self);
    [self.automationStore getSchedule:identifier completionHandler:^(UAScheduleData *scheduleData) {
        UA_STRONGIFY(self);

        // Verify we are still paused
        if (!scheduleData || [scheduleData.executionState intValue] != UAScheduleStatePaused) {
            return;
        }

        // Check expired
        if ([scheduleData isExpired]) {
            [self handleExpiredScheduleData:scheduleData];
            return;
        }

        // Capture the pause date
        NSDate *pauseDate = scheduleData.executionStateChangeDate;

        // Paused -> Idle
        scheduleData.executionState = @(UAScheduleStateIdle);

        // Check compound trigger state
        UASchedule *schedule = [self scheduleFromData:scheduleData];
        if (schedule) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UA_STRONGIFY(self);
                [self checkCompoundTriggerState:@[schedule] forStateNewerThanDate:pauseDate];
            });
        }

        // Finish the timer
        [self finishTimer:timer];
    }];
}

/**
 * Cancel timers by schedule identifiers.
 *
 * @param identifiers A set of identifiers to cancel.
 */
- (void)cancelTimersWithIdentifiers:(NSSet<NSString *> *)identifiers {
    for (NSTimer *timer in [self.activeTimers copy]) {
        if ([identifiers containsObject:timer.userInfo[@"identifier"]]) {
            if (timer.isValid) {
                [timer invalidate];
            }
            [self.activeTimers removeObject:timer];
        }
    }

    if (!self.activeTimers.count) {
        [self endBackgroundTask];
    }
}

/**
 * Cancel timers by schedule group.
 *
 * @param group A schedule group.
 */
- (void)cancelTimersWithGroup:(NSString *)group {
    for (NSTimer *timer in [self.activeTimers copy]) {
        if ([group isEqualToString:timer.userInfo[@"group"]]) {
            if (timer.isValid) {
                [timer invalidate];
            }
            [self.activeTimers removeObject:timer];
        }
    }

    if (!self.activeTimers.count) {
        [self endBackgroundTask];
    }
}

/**
 * Cancels all timers.
 */
- (void)cancelTimers {
    for (NSTimer *timer in self.activeTimers) {
        if (timer.isValid) {
            [timer invalidate];
        }
    }

    [self.activeTimers removeAllObjects];
    [self endBackgroundTask];
}

/**
 * Reschedules timers for any schedule that is pending execution and has a future delayed execution date.
 */
- (void)rescheduleTimers {
    [self cancelTimers];

    // Delay timers
    UA_WEAKIFY(self);
    [self.automationStore getSchedulesWithStates:@[@(UAScheduleStateTimeDelayed)] completionHandler:^(NSArray<UAScheduleData *> *schedules) {
        UA_STRONGIFY(self);
        for (UAScheduleData *scheduleData in schedules) {
            // If the delayedExecutionDate is greater than the original delay it probably means a clock adjustment. Reset the delay.
            if ([scheduleData.delayedExecutionDate timeIntervalSinceNow] > [scheduleData.delay.seconds doubleValue]) {
                scheduleData.delayedExecutionDate = [NSDate dateWithTimeIntervalSinceNow:[scheduleData.delay.seconds doubleValue]];
            }

            [self startTimerForSchedule:scheduleData
                           timeInterval:[scheduleData.delay.seconds doubleValue]
                               selector:@selector(delayTimerFired:)];
        }
    }];

    // Interval timers
    [self.automationStore getSchedulesWithStates:@[@(UAScheduleStatePaused)] completionHandler:^(NSArray<UAScheduleData *> *schedules) {
        UA_STRONGIFY(self);
        for (UAScheduleData *scheduleData in schedules) {
            NSTimeInterval interval = [scheduleData.interval doubleValue];
            NSTimeInterval pauseTime = -[scheduleData.executionStateChangeDate timeIntervalSinceNow];
            NSTimeInterval remainingTime = interval - pauseTime;
            if (remainingTime > interval) {
                remainingTime = interval;
            }

            [self startTimerForSchedule:scheduleData
                           timeInterval:remainingTime
                               selector:@selector(intervalTimerFired:)];
        }
    }];
}

/**
 * Resets schedules back to preparing schedule
 */
- (void)resetExecutingSchedules {
    id state = @[@(UAScheduleStateWaitingScheduleConditions),@(UAScheduleStateExecuting)];
    UA_WEAKIFY(self)
    [self.automationStore getSchedulesWithStates:state completionHandler:^(NSArray<UAScheduleData *> *schedules) {
        UA_STRONGIFY(self)
        for (UAScheduleData *scheduleData in schedules) {
            scheduleData.executionState = @(UAScheduleStatePreparingSchedule);
        }
        [self prepareSchedules:schedules];
    }];
}

/**
 * Sets up state conditions for use with compound triggers.
 */
- (void)createStateConditions {
    UAAutomationStateCondition *activeSessionCondition = [[UAAutomationStateCondition alloc] initWithPredicate:^BOOL {
        return [UIApplication sharedApplication].applicationState == UIApplicationStateActive;
    } argumentGenerator:nil];

    UAAutomationStateCondition *versionCondition = [[UAAutomationStateCondition alloc] initWithPredicate:^BOOL {
        return [UAirship shared].applicationMetrics.isAppVersionUpdated;
    } argumentGenerator:^id {
        NSString *currentVersion = [UAirship shared].applicationMetrics.currentAppVersion;
        return currentVersion ? @{@"ios" : @{@"version": currentVersion}} : nil;
    }];

    [self.stateConditions setObject:activeSessionCondition forKey:@(UAScheduleTriggerActiveSession)];
    [self.stateConditions setObject:versionCondition forKey:@(UAScheduleTriggerVersion)];
}

/**
 * Checks compound trigger state for currently active schedules, to be
 * called at start.
 */
- (void)restoreCompoundTriggers {
    UA_WEAKIFY(self)
    [self getSchedules:^(NSArray<UASchedule *> *schedules) {
        UA_STRONGIFY(self)
        [self checkCompoundTriggerState:schedules];
    }];
}

/**
 * Sorts provided schedules in ascending prioirty order and checks whether any compound triggers
 * assigned to those schedules have currently valid state conditions, updating them if necessary.
 *
 * @param schedules The schedules.
 */
- (void)checkCompoundTriggerState:(NSArray<UASchedule *> *)schedules {
    [self checkCompoundTriggerState:schedules forStateNewerThanDate:[NSDate distantPast]];
}

/**
 * Sorts provided schedules in ascending prioirty order and checks whether any compound triggers
 * assigned to those schedules have currently valid state conditions, updating them if necessary.
 *
 * @param schedules The schedules.
 * @param date Filters out state triggers based on the state change date.
 */
- (void)checkCompoundTriggerState:(NSArray<UASchedule *> *)schedules forStateNewerThanDate:(NSDate *)date {
    // Sort schedules by priority in ascending order
    schedules = [self sortedSchedulesByPriority:schedules];

    for (UASchedule *schedule in schedules) {
        NSMutableArray *checkedTriggerTypes = [NSMutableArray array];
        for (UAScheduleTrigger *trigger in schedule.info.triggers) {
            UAScheduleTriggerType type = trigger.type;
            UAAutomationStateCondition *condition = self.stateConditions[@(type)];

            if (!condition || [checkedTriggerTypes containsObject:@(type)]) {
                continue;
            }

            // If there is a matching condition and the condition holds, update all of the schedule's triggers of that type
            if ([date compare:condition.stateChangeDate] == NSOrderedAscending && condition.predicate()) {
                id argument = condition.argumentGenerator ? condition.argumentGenerator() : nil;
                [self updateTriggersWithScheduleID:schedule.identifier type:type argument:argument incrementAmount:1.0];
            }

            [checkedTriggerTypes addObject:@(type)];
        }
    }
}

/**
 * Called when one of the schedule conditions changes.
 */
- (void)scheduleConditionsChanged {
    UA_WEAKIFY(self)
    [self.automationStore getSchedulesWithStates:@[@(UAScheduleStateWaitingScheduleConditions)]
                               completionHandler:^(NSArray<UAScheduleData *> *schedulesData) {
                                   UA_STRONGIFY(self);
                                   schedulesData = [self sortedScheduleDataByPriority:schedulesData];
                                   for (UAScheduleData *scheduleData in schedulesData) {
                                       [self attemptExecution:scheduleData];
                                   }
                               }];
}

/**
 * Checks if a schedule that is pending execution is able to be executed.
 *
 * @param scheduleDelay The UAScheduleDelay to check.
 * @return YES if conditions are satisfied, otherwise NO.
 */
- (BOOL)isScheduleDelaySatisfied:(UAScheduleDelay *)scheduleDelay {
    if (!scheduleDelay) {
        return YES;
    }

    if (scheduleDelay.screens && ![scheduleDelay.screens containsObject:self.currentScreen]) {
        return NO;
    }

    if (scheduleDelay.regionID && ![scheduleDelay.regionID isEqualToString:self.currentRegion]) {
        return NO;
    }

    if (scheduleDelay.appState == UAScheduleDelayAppStateForeground && !self.isForegrounded) {
        return NO;
    }

    if (scheduleDelay.appState == UAScheduleDelayAppStateBackground && self.isForegrounded) {
        return NO;
    }

    return YES;
}

/**
 * Processes triggered schedules.
 *
 * @param schedules An array of triggered schedule data.
 */
- (void)processTriggeredSchedules:(NSArray<UAScheduleData *> *)schedules {
    if (!schedules.count || self.paused) {
        return;
    }

    NSMutableArray *schedulesToPrepare = [NSMutableArray array];


    for (UAScheduleData *scheduleData in schedules) {
        if ([scheduleData.executionState intValue] != UAScheduleStateIdle) {
            continue;
        }

        // Check expired
        if ([scheduleData isExpired]) {
            [self handleExpiredScheduleData:scheduleData];
            continue;
        }

        // Reset cancellation triggers
        for (UAScheduleTriggerData *cancellationTrigger in scheduleData.delay.cancellationTriggers) {
            cancellationTrigger.goalProgress = 0;
        }

        // Check for time delay
        if ([scheduleData.delay.seconds doubleValue] > 0) {
            scheduleData.executionState = @(UAScheduleStateTimeDelayed);
            scheduleData.delayedExecutionDate = [NSDate dateWithTimeIntervalSinceNow:[scheduleData.delay.seconds doubleValue]];

            // Start a timer
            [self startTimerForSchedule:scheduleData
                           timeInterval:[scheduleData.delay.seconds doubleValue]
                               selector:@selector(delayTimerFired:)];
            continue;
        }

        [schedulesToPrepare addObject:scheduleData];
        scheduleData.executionState = @(UAScheduleStatePreparingSchedule);
    }

    [self prepareSchedules:schedulesToPrepare];
}

- (void)prepareSchedules:(NSArray<UAScheduleData *> *)schedules {
    if (!schedules.count) {
        return;
    }

    // Sort schedules by priority in ascending order
    schedules = [self sortedScheduleDataByPriority:schedules];

    for (UAScheduleData *scheduleData in schedules) {
        NSString *scheduleID = scheduleData.identifier;

        UASchedule *schedule = [self scheduleFromData:scheduleData];
        if (!schedule) {
            continue;
        }

        UA_WEAKIFY(self)
        [self.delegate prepareSchedule:schedule completionHandler:^(UAAutomationSchedulePrepareResult prepareResult) {
            UA_STRONGIFY(self)

            // Get the updated schedule
            [self.automationStore getSchedule:scheduleID completionHandler:^(UAScheduleData *scheduleData) {
                UA_STRONGIFY(self)
                if (!scheduleData) {
                    return;
                }

                // Make sure it's still preparing
                if ([scheduleData.executionState intValue] != UAScheduleStatePreparingSchedule) {
                    return;
                }

                // Handle expired
                if ([scheduleData isExpired]) {
                    [self handleExpiredScheduleData:scheduleData];
                }

                switch (prepareResult) {
                    case UAAutomationSchedulePrepareResultCancel:
                        [scheduleData.managedObjectContext deleteObject:scheduleData];
                        break;
                    case UAAutomationSchedulePrepareResultContinue:
                        scheduleData.executionState = @(UAScheduleStateWaitingScheduleConditions);
                        [self attemptExecution:scheduleData];
                        break;
                    case UAAutomationSchedulePrepareResultSkip:
                        scheduleData.executionState = @(UAScheduleStateIdle);
                        break;

                    case UAAutomationSchedulePrepareResultPenalize:
                    default:
                        [self scheduleFinishedExecuting:scheduleData];
                        break;
                }
            }];
        }];
    }
}


- (void)attemptExecution:(UAScheduleData *)scheduleData {
    if ([scheduleData.executionState intValue] != UAScheduleStateWaitingScheduleConditions) {
        UA_LERR(@"Unable to execute schedule. Schedule is in the wrong state: %@", scheduleData.executionState);
        return;
    }

    // Verify the schedule is not expired
    if ([scheduleData isExpired]) {
        [self handleExpiredScheduleData:scheduleData];
        return;
    }

    UASchedule *schedule = [self scheduleFromData:scheduleData];
    if (!schedule) {
        return;
    }

    __block BOOL scheduleExecuting = NO;

    // Conditions and action executions must be run on the main queue.
    UA_WEAKIFY(self)
    dispatch_sync(dispatch_get_main_queue(), ^{
        UA_STRONGIFY(self)

        if (self.paused) {
            return;
        }

        if (![self isScheduleDelaySatisfied:schedule.info.delay]) {
            UA_LDEBUG("Schedule:%@ is not ready to execute. Conditions not satisfied", schedule);
            return;
        }

        if (![self.delegate isScheduleReadyToExecute:schedule]) {
            UA_LDEBUG("Schedule:%@ is not ready to execute.", schedule);
            return;
        }

        [self.delegate executeSchedule:schedule completionHandler:^{
            UA_STRONGIFY(self)
            [self.automationStore getSchedule:schedule.identifier completionHandler:^(UAScheduleData *scheduleData) {
                UA_STRONGIFY(self)
                [self scheduleFinishedExecuting:scheduleData];
            }];
        }];

        scheduleExecuting = YES;
    });

    if (scheduleExecuting) {
        scheduleData.executionState = @(UAScheduleStateExecuting); // executing
    }
}

- (void)handleExpiredScheduleData:(nonnull UAScheduleData *)scheduleData {
    UA_LTRACE(@"Schedule expired: %@", scheduleData.identifier);
    [self finishOrDeleteSchedule:scheduleData];

    UA_WEAKIFY(self)
    dispatch_async(dispatch_get_main_queue(), ^{
        UA_STRONGIFY(self)
        id<UAAutomationEngineDelegate> delegate = self.delegate;
        if ([delegate respondsToSelector:@selector(scheduleExpired:)]) {
            UASchedule *schedule = [self scheduleFromData:scheduleData];
            if (schedule) {
                [delegate scheduleExpired:schedule];
            }
        }
    });
}

- (void)finishOrDeleteSchedule:(UAScheduleData *)scheduleData {
    UA_LTRACE(@"Schedule expired: %@", scheduleData.identifier);
    scheduleData.executionState = @(UAScheduleStateFinished);

    if ([scheduleData.editGracePeriod doubleValue] <= 0) {
        UA_LDEBUG(@"Deleting schedule: %@", scheduleData.identifier);
        [scheduleData.managedObjectContext deleteObject:scheduleData];
    }
}

- (void)scheduleFinishedExecuting:(UAScheduleData *)scheduleData {
    if (!scheduleData) {
        return;
    }

    UA_LTRACE(@"Schedule finished executing %@", scheduleData.identifier);

    // Increment the count
    scheduleData.triggeredCount = @([scheduleData.triggeredCount integerValue] + 1);

    // Expired
    if ([scheduleData isExpired]) {
        [self handleExpiredScheduleData:scheduleData];
        return;
    }

    if ([scheduleData isOverLimit]) {
        // Over limit
        UA_LDEBUG(@"Limit reached for schedule %@", scheduleData.identifier);
        [self finishOrDeleteSchedule:scheduleData];
    } else if ([scheduleData.interval doubleValue] > 0) {
        // Paused
        scheduleData.executionState = @(UAScheduleStatePaused);
        [self startTimerForSchedule:scheduleData
                       timeInterval:[scheduleData.interval doubleValue]
                           selector:@selector(intervalTimerFired:)];
    } else {
        // Back to idle
        scheduleData.executionState = @(UAScheduleStateIdle);
    }
}

/**
 * Helper method to end the background task if its not invalid.
 */
- (void)endBackgroundTask {
    if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
}

#pragma mark -
#pragma mark Converters

- (UASchedule *)scheduleFromData:(UAScheduleData *)scheduleData {
    UAScheduleInfoBuilder *builder = [[UAScheduleInfoBuilder alloc] init];
    builder.triggers = [UAAutomationEngine triggersFromData:scheduleData.triggers];
    builder.delay = [UAAutomationEngine delayFromData:scheduleData.delay];
    builder.group = scheduleData.group;
    builder.data = scheduleData.data;
    builder.start = scheduleData.start;
    builder.end = scheduleData.end;
    builder.priority = [scheduleData.priority integerValue];
    builder.limit = [scheduleData.limit unsignedIntegerValue];
    builder.interval = [scheduleData.interval doubleValue];
    builder.editGracePeriod = [scheduleData.editGracePeriod doubleValue];

    UASchedule *schedule;
    UAScheduleInfo *info = [self.delegate createScheduleInfoWithBuilder:builder];

    if (![info isValid]) {
        UA_LERR(@"Info is invalid: %@", info);
        schedule = nil;
    } else {
        schedule = [UASchedule scheduleWithIdentifier:scheduleData.identifier info:info];
    }

    if (!schedule) {
        UA_LERR(@"Failed to parse schedule data. Deleting %@", scheduleData.identifier);
        [scheduleData.managedObjectContext deleteObject:scheduleData];
    }

    return schedule;
}

+ (NSArray<UAScheduleTrigger *> *)triggersFromData:(NSSet<UAScheduleTriggerData *> *)data {
    NSMutableArray *triggers = [NSMutableArray array];

    for (UAScheduleTriggerData *triggerData in data) {
        UAScheduleTrigger *trigger = [UAScheduleTrigger triggerWithType:(UAScheduleTriggerType)[triggerData.type integerValue]
                                                                   goal:triggerData.goal
                                                              predicate:[UAAutomationEngine predicateFromData:triggerData.predicateData]];

        [triggers addObject:trigger];
    }

    return triggers;
}


+ (UAScheduleDelay *)delayFromData:(UAScheduleDelayData *)data {
    if (!data) {
        return nil;
    }

    return [UAScheduleDelay delayWithBuilderBlock:^(UAScheduleDelayBuilder *builder) {
        builder.seconds = [data.seconds doubleValue];
        NSData *screenData = [data.screens dataUsingEncoding:NSUTF8StringEncoding];
        if (screenData != nil) {
            builder.screens = [NSJSONSerialization JSONObjectWithData:screenData options:NSJSONReadingMutableContainers error:nil];
        }
        builder.regionID = data.regionID;
        builder.cancellationTriggers = [UAAutomationEngine triggersFromData:data.cancellationTriggers];
        builder.appState = [data.appState integerValue];
    }];
}

+ (UAJSONPredicate *)predicateFromData:(NSData *)data {
    if (!data) {
        return nil;
    }

    id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    return [UAJSONPredicate predicateWithJSON:json error:nil];
}

+ (void)applyEdits:(UAScheduleEdits *)edits toData:(UAScheduleData *)scheduleData {
    if (edits.data) {
        scheduleData.data = edits.data;
    }

    if (edits.start) {
        scheduleData.start = edits.start;
    }

    if (edits.end) {
        scheduleData.end = edits.end;
    }

    if (edits.interval) {
        scheduleData.interval = edits.interval;
    }

    if (edits.editGracePeriod) {
        scheduleData.editGracePeriod = edits.editGracePeriod;
    }

    if (edits.limit) {
        scheduleData.limit = edits.limit;
    }

    if (edits.priority) {
        scheduleData.priority = edits.priority;
    }
}

@end


