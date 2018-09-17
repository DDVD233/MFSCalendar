/* Copyright 2018 Urban Airship and Contributors */

#import "UAInAppMessageManager+Internal.h"
#import "UAInAppMessageAdapterProtocol.h"
#import "UAInAppMessageScheduleInfo.h"
#import "UAScheduleInfo+Internal.h"
#import "NSJSONSerialization+UAAdditions.h"
#import "UAInAppMessageBannerAdapter.h"
#import "UAInAppMessageFullScreenAdapter.h"
#import "UAInAppMessageModalAdapter.h"
#import "UAInAppMessageHTMLAdapter.h"
#import "UAGlobal.h"
#import "UAConfig.h"
#import "UAInAppRemoteDataClient+Internal.h"
#import "UAPreferenceDataStore+Internal.h"
#import "UAInAppMessageAudienceChecks+Internal.h"
#import "UAPreferenceDataStore+Internal.h"
#import "UAInAppMessage+Internal.h"
#import "UAAsyncOperation+Internal.h"
#import "UAActionRunner+Internal.h"
#import "UAInAppMessageResolutionEvent+Internal.h"
#import "UAInAppMessageDisplayEvent+Internal.h"
#import "UAirship.h"
#import "UAActiveTimer+Internal.h"
#import "UAInAppMessageAudience.h"
#import "UAInAppMessagingRemoteConfig+Internal.h"
#import "UATagGroupsLookupManager+Internal.h"
#import "UARetriable+Internal.h"
#import "UARetriablePipeline+Internal.h"
#import "UAInAppMessageTagSelector+Internal.h"

NS_ASSUME_NONNULL_BEGIN

NSTimeInterval const DefaultMessageDisplayInterval = 30;
NSTimeInterval const MaxSchedules = 200;
NSTimeInterval const MessagePrepareRetryDelay = 30;

NSString *const UAInAppAutomationStoreFileFormat = @"In-app-automation-%@.sqlite";
NSString *const UAInAppMessageManagerEnabledKey = @"UAInAppMessageManagerEnabled";
NSString *const UAInAppMessageManagerPausedKey = @"UAInAppMessageManagerPaused";

@interface UAInAppMessageScheduleData : NSObject

@property(nonatomic, strong, nonnull) id<UAInAppMessageAdapterProtocol> adapter;
@property(nonatomic, copy, nonnull) NSString *scheduleID;
@property(nonatomic, strong, nonnull) UAInAppMessage *message;

+ (instancetype)dataWithAdapter:(id<UAInAppMessageAdapterProtocol>)adapter scheduleID:(NSString *)scheduleID message:(UAInAppMessage *)message;

@end

@implementation UAInAppMessageScheduleData

- (instancetype)initWithAdapter:(id<UAInAppMessageAdapterProtocol>)adapter scheduleID:(NSString *)scheduleID message:(UAInAppMessage *)message {
    self = [super init];
    if (self) {
        self.adapter = adapter;
        self.scheduleID = scheduleID;
        self.message = message;
    }
    return self;
}

+ (instancetype)dataWithAdapter:(id<UAInAppMessageAdapterProtocol>)adapter scheduleID:(NSString *)scheduleID message:(UAInAppMessage *)message {
    return [[self alloc] initWithAdapter:adapter scheduleID:scheduleID message:message];
}

@end

@interface UAInAppMessageManager ()

@property(nonatomic, assign) BOOL isDisplayLocked;
@property(nonatomic, strong) NSMutableDictionary *adapterFactories;
@property(nonatomic, strong) UAAutomationEngine *automationEngine;
@property(nonatomic, strong) NSMutableDictionary *adapters;
@property(nonatomic, strong) UAInAppRemoteDataClient *remoteDataClient;
@property(nonatomic, strong) UAPreferenceDataStore *dataStore;
@property(nonatomic, strong) NSOperationQueue *queue;
@property(nonatomic, strong) NSMutableDictionary *scheduleData;
@property(nonatomic, strong) UATagGroupsLookupManager *tagGroupsLookupManager;
@property(nonatomic, strong) UADispatcher *dispatcher;
@property(nonatomic, strong) UARetriablePipeline *prepareSchedulePipeline;

@end

@implementation UAInAppMessageManager

+ (instancetype)managerWithAutomationEngine:(UAAutomationEngine *)automationEngine
                     tagGroupsLookupManager:(UATagGroupsLookupManager *)tagGroupsLookupManager
                          remoteDataManager:(UARemoteDataManager *)remoteDataManager
                                  dataStore:(UAPreferenceDataStore *)dataStore
                                       push:(UAPush *)push
                                 dispatcher:(UADispatcher *)dispatcher {

    return [[self alloc] initWithAutomationEngine:automationEngine
                           tagGroupsLookupManager:tagGroupsLookupManager
                                remoteDataManager:remoteDataManager
                                        dataStore:dataStore
                                             push:push
                                       dispatcher:dispatcher];
}

+ (instancetype)managerWithConfig:(UAConfig *)config
         tagGroupsMutationHistory:(UATagGroupsMutationHistory *)tagGroupsMutationHistory
                remoteDataManager:(UARemoteDataManager *)remoteDataManager
                        dataStore:(UAPreferenceDataStore *)dataStore
                             push:(UAPush *)push {

    NSString *storeName = [NSString stringWithFormat:UAInAppAutomationStoreFileFormat, config.appKey];

    UAAutomationStore *store = [UAAutomationStore automationStoreWithStoreName:storeName scheduleLimit:MaxSchedules];
    UAAutomationEngine *automationEngine = [UAAutomationEngine automationEngineWithAutomationStore:store];

    UATagGroupsLookupManager *tagGroupsLookupManager = [UATagGroupsLookupManager lookupManagerWithConfig:config
                                                                                               dataStore:dataStore
                                                                                         mutationHistory:tagGroupsMutationHistory];

     return [[UAInAppMessageManager alloc] initWithAutomationEngine:automationEngine
                                             tagGroupsLookupManager:tagGroupsLookupManager
                                                  remoteDataManager:remoteDataManager
                                                          dataStore:dataStore
                                                               push:push
                                                         dispatcher:[UADispatcher mainDispatcher]];
}

- (instancetype)initWithAutomationEngine:(UAAutomationEngine *)automationEngine
                  tagGroupsLookupManager:(UATagGroupsLookupManager *)tagGroupsLookupManager
                       remoteDataManager:(UARemoteDataManager *)remoteDataManager
                               dataStore:(UAPreferenceDataStore *)dataStore
                                    push:(UAPush *)push
                              dispatcher:(UADispatcher *)dispatcher {

    self = [super initWithDataStore:dataStore];

    if (self) {
        self.queue = [[NSOperationQueue alloc] init];
        self.queue.maxConcurrentOperationCount = 1;
        self.scheduleData = [NSMutableDictionary dictionary];
        self.adapterFactories = [NSMutableDictionary dictionary];
        self.adapters = [NSMutableDictionary dictionary];
        self.dataStore = dataStore;
        self.automationEngine = automationEngine;
        self.automationEngine.delegate = self;
        self.tagGroupsLookupManager = tagGroupsLookupManager;
        self.tagGroupsLookupManager.delegate = self;
        self.displayInterval = DefaultMessageDisplayInterval;
        self.remoteDataClient = [UAInAppRemoteDataClient clientWithScheduler:self remoteDataManager:remoteDataManager dataStore:dataStore push:push];
        self.dispatcher = dispatcher;
        self.prepareSchedulePipeline = [UARetriablePipeline pipeline];

        [self setDefaultAdapterFactories];

        [self.automationEngine start];
        [self updateEnginePauseState];
    }

    return self;
}

// Sets the default adapter factories
- (void)setDefaultAdapterFactories {
    // Banner
    [self setFactoryBlock:^id<UAInAppMessageAdapterProtocol> _Nonnull(UAInAppMessage * _Nonnull message) {
        return [UAInAppMessageBannerAdapter adapterForMessage:message];
    } forDisplayType:UAInAppMessageDisplayTypeBanner];

    // Full Screen
    [self setFactoryBlock:^id<UAInAppMessageAdapterProtocol> _Nonnull(UAInAppMessage * _Nonnull message) {
        return [UAInAppMessageFullScreenAdapter adapterForMessage:message];
    } forDisplayType:UAInAppMessageDisplayTypeFullScreen];

    // Modal
    [self setFactoryBlock:^id<UAInAppMessageAdapterProtocol> _Nonnull(UAInAppMessage * _Nonnull message) {
        return [UAInAppMessageModalAdapter adapterForMessage:message];
    } forDisplayType:UAInAppMessageDisplayTypeModal];

    [self setFactoryBlock:^id<UAInAppMessageAdapterProtocol> _Nonnull(UAInAppMessage * _Nonnull message) {
        return [UAInAppMessageHTMLAdapter adapterForMessage:message];
    } forDisplayType:UAInAppMessageDisplayTypeHTML];
}

- (void)getScheduleWithID:(NSString *)identifier completionHandler:(void (^)(UASchedule *))completionHandler {
    [self.automationEngine getScheduleWithID:identifier completionHandler:completionHandler];
}

- (void)getSchedulesWithMessageID:(NSString *)messageID completionHandler:(void (^)(NSArray<UASchedule *> *))completionHandler {
    [self.automationEngine getSchedulesWithGroup:messageID completionHandler:completionHandler];
}

- (void)scheduleMessageWithScheduleInfo:(UAInAppMessageScheduleInfo *)scheduleInfo
                      completionHandler:(void (^)(UASchedule *))completionHandler {
    [self.automationEngine schedule:scheduleInfo completionHandler:completionHandler];;
}

- (void)scheduleMessagesWithScheduleInfo:(NSArray<UAInAppMessageScheduleInfo *> *)scheduleInfos completionHandler:(void (^)(NSArray <UASchedule *> *))completionHandler {
    [self.automationEngine scheduleMultiple:scheduleInfos completionHandler:completionHandler];
}

- (void)cancelMessagesWithID:(NSString *)identifier {
    [self.automationEngine cancelSchedulesWithGroup:identifier];
}

- (void)cancelScheduleWithID:(NSString *)scheduleID {
    [self.automationEngine cancelScheduleWithID:scheduleID];
}

- (void)editScheduleWithID:(NSString *)identifier
                     edits:(UAInAppMessageScheduleEdits *)edits
         completionHandler:(void (^)(UASchedule * __nullable))completionHandler {

    [self.automationEngine editScheduleWithID:identifier edits:edits completionHandler:completionHandler];
}

- (UAScheduleInfo *)createScheduleInfoWithBuilder:(UAScheduleInfoBuilder *)builder {
    return [[UAInAppMessageScheduleInfo alloc] initWithBuilder:builder];
}

- (void)setFactoryBlock:(id<UAInAppMessageAdapterProtocol> (^)(UAInAppMessage* message))factory
         forDisplayType:(UAInAppMessageDisplayType)displayType {

    if (factory) {
        self.adapterFactories[@(displayType)] = factory;
    } else {
        [self.adapterFactories removeObjectForKey:@(displayType)];
    }
}

- (void)unlockDisplayAfter:(NSTimeInterval)interval {
    UA_WEAKIFY(self)
    [self.dispatcher dispatchAfter:interval block:^{
        UA_STRONGIFY(self)
        self.isDisplayLocked = NO;
        [self.automationEngine scheduleConditionsChanged];
    }];
}

- (void)lockDisplay {
    self.isDisplayLocked = YES;
}

- (id<UAInAppMessageAdapterProtocol>)createAdapterForMessage:(UAInAppMessage *)message scheduleID:(NSString *)scheduleID {
    id<UAInAppMessageAdapterProtocol> (^factory)(UAInAppMessage* message) = self.adapterFactories[@(message.displayType)];

    if (!factory) {
        UA_LWARN(@"Factory unavailable for message: %@", message);
        return nil;
    }

    id<UAInAppMessageAdapterProtocol> adapter = factory(message);
    [self.adapters setObject:adapter forKey:scheduleID];

    return adapter;
}

- (UARetriable *)adapterRetriableWithMessage:(UAInAppMessage *)message scheduleID:(NSString *)scheduleID resultHandler:(UARetriableCompletionHandler)resultHandler {
    UA_WEAKIFY(self)
    return [UARetriable retriableWithRunBlock:^(UARetriableCompletionHandler handler) {
        UA_STRONGIFY(self)
        id<UAInAppMessageAdapterProtocol> adapter = [self createAdapterForMessage:message scheduleID:scheduleID];

        if (!adapter) {
            handler(UARetriableResultCancel);
        } else {
            handler(UARetriableResultSuccess);
        }
    } resultHandler:resultHandler];
}

- (UARetriable *)audienceChecksRetriableWithMessage:(UAInAppMessage *)message resultHandler:(UARetriableCompletionHandler)resultHandler {
    return [UARetriable retriableWithRunBlock:^(UARetriableCompletionHandler handler) {
        void (^performAudienceCheck)(UATagGroups *) = ^(UATagGroups *tagGroups) {
            if ([UAInAppMessageAudienceChecks checkDisplayAudienceConditions:message.audience tagGroups:tagGroups]) {
                handler(UARetriableResultSuccess);
            } else {
                handler(UARetriableResultCancel);
            }
        };

        UATagGroups *requestedTagGroups = message.audience.tagSelector.tagGroups;

        if (requestedTagGroups.tags.count) {
            [self.tagGroupsLookupManager getTagGroups:requestedTagGroups completionHandler:^(UATagGroups * _Nullable tagGroups, NSError * _Nonnull error) {
                if (error) {
                    handler(UARetriableResultRetry);
                } else {
                    performAudienceCheck(tagGroups);
                }
            }];
        } else {
            performAudienceCheck(nil);
        }
    } resultHandler:resultHandler];
}

- (UARetriable *)prepareMessageDataRetriableWithMessage:(UAInAppMessage *)message
                                             scheduleID:(NSString *)scheduleID
                                          resultHandler:(UARetriableCompletionHandler)resultHandler {

    UA_WEAKIFY(self)
    return [UARetriable retriableWithRunBlock:^(UARetriableCompletionHandler handler) {
        UA_STRONGIFY(self)

        id<UAInAppMessageAdapterProtocol> adapter = self.adapters[scheduleID];

        if (!adapter) {
            handler(UARetriableResultCancel);
        }

        UAInAppMessageScheduleData *data = [UAInAppMessageScheduleData dataWithAdapter:adapter
                                                                            scheduleID:scheduleID
                                                                               message:message];

        [self.dispatcher dispatchAsync:^{
            [adapter prepare:^(UAInAppMessagePrepareResult prepareResult) {
                UA_STRONGIFY(self)

                UA_LDEBUG(@"Prepare result: %ld schedule: %@", (unsigned long)prepareResult, scheduleID);
                switch (prepareResult) {
                    case UAInAppMessagePrepareResultSuccess:
                        self.scheduleData[scheduleID] = data;
                        handler(UARetriableResultSuccess);
                        break;

                    case UAInAppMessagePrepareResultRetry:
                        handler(UARetriableResultRetry);
                        break;

                    case UAInAppMessagePrepareResultCancel:
                        handler(UARetriableResultCancel);
                        break;
                }
            }];
        }];

    } resultHandler:resultHandler];
}

- (void)prepareMessage:(UAInAppMessage *)message scheduleID:(NSString *)scheduleID completionHandler:(void (^)(UAAutomationSchedulePrepareResult))completionHandler {

    // Create the adapter
    UARetriable *createAdapter = [self adapterRetriableWithMessage:message scheduleID:scheduleID resultHandler:^(UARetriableResult result) {
        if (result == UARetriableResultCancel) {
            UA_LWARN(@"Failed to build adapter for message: %@, skipping display for schedule: %@", message, scheduleID);
            completionHandler(UAAutomationSchedulePrepareResultPenalize);
        }
    }];

    // Check audience conditions
    UARetriable *audienceChecks = [self audienceChecksRetriableWithMessage:message resultHandler:^(UARetriableResult result) {
        if (result == UARetriableResultCancel) {
            UA_LDEBUG(@"Message audience conditions not met, skipping display for schedule: %@, missBehavior: %ld", scheduleID, (long)message.audience.missBehavior);
            UAAutomationSchedulePrepareResult prepareResult;

            switch(message.audience.missBehavior) {
                case UAInAppMessageAudienceMissBehaviorCancel:
                    prepareResult = UAAutomationSchedulePrepareResultCancel;
                    break;
                case UAInAppMessageAudienceMissBehaviorSkip:
                    prepareResult = UAAutomationSchedulePrepareResultSkip;
                    break;
                case UAInAppMessageAudienceMissBehaviorPenalize:
                    prepareResult = UAAutomationSchedulePrepareResultPenalize;
                    break;
            }

            completionHandler(prepareResult);
        }
    }];

    // Prepare the data
    UARetriable *prepareMessageData = [self prepareMessageDataRetriableWithMessage:message scheduleID:scheduleID resultHandler:^(UARetriableResult result) {
        if (result == UARetriableResultCancel) {
            UA_LDEBUG(@"Unable to prepare message data, cancelling schedule: %@", scheduleID);
            completionHandler(UAAutomationSchedulePrepareResultCancel);
        } else if (result == UARetriableResultSuccess) {
            completionHandler(UAAutomationSchedulePrepareResultContinue);
        }
    }];

    [self.prepareSchedulePipeline addChainedRetriables:@[createAdapter, audienceChecks, prepareMessageData]];
}

- (void)prepareSchedule:(nonnull UASchedule *)schedule completionHandler:(void (^)(UAAutomationSchedulePrepareResult))completionHandler {
    UAInAppMessageScheduleInfo *info = (UAInAppMessageScheduleInfo *)schedule.info;
    UAInAppMessage *message = info.message;

    // Allow the delegate to extend the message if desired.
    if ([self.delegate respondsToSelector:@selector(extendMessage:)]) {
        message = [self.delegate extendMessage:message];
        if (!message) {
            UA_LERR(@"Error extending message");
            completionHandler(UAAutomationSchedulePrepareResultPenalize);
            return;
        }
    }

    [self prepareMessage:message scheduleID:schedule.identifier completionHandler:completionHandler];
}

- (BOOL)isScheduleReadyToExecute:(UASchedule *)schedule {
    UA_LTRACE(@"Checking if schedule %@ is ready to execute.", schedule.identifier);

    // Require an active application
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        UA_LTRACE(@"Application is not active. Schedule: %@ not ready", schedule.identifier);
        return NO;
    }

    // If the display is locked via timer or manager
    if (self.isDisplayLocked) {
        UA_LTRACE(@"Display is locked. Schedule: %@ not ready.", schedule.identifier);
        return NO;
    }

    // If manager is paused
    if (self.isPaused) {
        UA_LTRACE(@"Message display is currently paused. Schedule: %@ not ready.", schedule.identifier);
        return NO;
    }

    UAInAppMessageScheduleData *data = self.scheduleData[schedule.identifier];

    if (!data) {
        UA_LERR("No data for schedule: %@", schedule.identifier);
        return NO;
    }

    if (![data.adapter isReadyToDisplay]) {
        UA_LTRACE(@"Adapter ready check failed. Schedule: %@ not ready.", schedule.identifier);
        return NO;
    }

    UA_LTRACE(@"Schedule %@ ready!", schedule.identifier);
    return YES;
}

- (void)executeSchedule:(nonnull UASchedule *)schedule
      completionHandler:(void (^)(void))completionHandler {

    UA_LTRACE(@"Executing schedule: %@", schedule.identifier);

    UAInAppMessageScheduleInfo *info = (UAInAppMessageScheduleInfo *)schedule.info;
    UAInAppMessage *message = info.message;
    UAInAppMessageScheduleData *scheduleData = self.scheduleData[schedule.identifier];

    if (!scheduleData) {
        completionHandler();
        return;
    }

    id<UAInAppMessageAdapterProtocol> adapter = scheduleData.adapter;

    // Lock Display
    [self lockDisplay];

    // Notify delegate that the message is about to be displayed
    if ([self.delegate respondsToSelector:@selector(messageWillBeDisplayed:scheduleID:)]) {
        [self.delegate messageWillBeDisplayed:message scheduleID:schedule.identifier];
    }

    // Display event
    UAEvent *event = [UAInAppMessageDisplayEvent eventWithMessage:message];
    [[UAirship analytics] addEvent:event];

    // Display time timer
    UAActiveTimer *timer = [[UAActiveTimer alloc] init];
    [timer start];

    UA_WEAKIFY(self);
    [adapter display:^(UAInAppMessageResolution *resolution) {
        UA_STRONGIFY(self);
        UA_LDEBUG(@"Schedule %@ finished displaying", schedule.identifier);

        [self.adapters removeObjectForKey:schedule.identifier];

        // Resolution event
        [timer stop];
        UAEvent *event = [UAInAppMessageResolutionEvent eventWithMessage:message resolution:resolution displayTime:timer.time];
        [[UAirship analytics] addEvent:event];

        // Cancel button
        if (resolution.type == UAInAppMessageResolutionTypeButtonClick && resolution.buttonInfo.behavior == UAInAppMessageButtonInfoBehaviorCancel) {
            [self cancelScheduleWithID:schedule.identifier];
        }

        if (message.actions) {
            [UAActionRunner runActionsWithActionValues:message.actions
                                             situation:UASituationManualInvocation
                                              metadata:nil
                                     completionHandler:^(UAActionResult *result) {
                                         UA_LTRACE(@"Finished running actions for schedule %@", schedule.identifier);
                                     }];
        }

        // Start timer to unlock display after display interval
        [self unlockDisplayAfter:self.displayInterval];
        [self.scheduleData removeObjectForKey:schedule.identifier];

        // Notify delegate that the message has finished displaying
        if ([self.delegate respondsToSelector:@selector(messageFinishedDisplaying:scheduleID:resolution:)]) {
            [self.delegate messageFinishedDisplaying:message scheduleID:schedule.identifier resolution:resolution];
        }

        completionHandler();
    }];
}

- (void)scheduleExpired:(UASchedule *)schedule {
    UAInAppMessageScheduleInfo *info = (UAInAppMessageScheduleInfo *)schedule.info;
    UAEvent *event = [UAInAppMessageResolutionEvent eventWithExpiredMessage:info.message expiredDate:info.end];
    [[UAirship analytics] addEvent:event];
}

- (void)onComponentEnableChange {
    [self updateEnginePauseState];
}

- (Class)remoteConfigClass {
    return [UAInAppMessagingRemoteConfig class];
}

- (void)onNewRemoteConfig:(UARemoteConfig *)config {
    UAInAppMessagingRemoteConfig *newConfig = (UAInAppMessagingRemoteConfig *)config;

    self.tagGroupsLookupManager.componentEnabled = newConfig.tagGroupsConfig.enabled;
    self.tagGroupsLookupManager.cacheMaxAgeTime = newConfig.tagGroupsConfig.cacheMaxAgeTime;
    self.tagGroupsLookupManager.cacheStaleReadTime = newConfig.tagGroupsConfig.cacheStaleReadTime;
    self.tagGroupsLookupManager.preferLocalTagDataTime = newConfig.tagGroupsConfig.cachePreferLocalUntil;
}

- (void)setPaused:(BOOL)paused {

    // If we're unpausing, alert the automation engine
    if (self.isPaused == YES && self.isPaused != paused) {
        [self.automationEngine scheduleConditionsChanged];
    }

    [self.dataStore setBool:paused forKey:UAInAppMessageManagerPausedKey];
}

- (BOOL)isPaused{
    return [self.dataStore boolForKey:UAInAppMessageManagerPausedKey defaultValue:NO];
}

- (void)setEnabled:(BOOL)enabled {
    [self.dataStore setBool:enabled forKey:UAInAppMessageManagerEnabledKey];
    [self updateEnginePauseState];
}

- (BOOL)isEnabled {
    return [self.dataStore boolForKey:UAInAppMessageManagerEnabledKey defaultValue:YES];
}

- (void)updateEnginePauseState {
    if (self.componentEnabled && self.isEnabled) {
        [self.automationEngine resume];
    } else {
        [self.automationEngine pause];
    }
}

- (void)dealloc {
    [self.automationEngine stop];
    self.automationEngine.delegate = nil;
}

- (void)gatherTagGroupsWithCompletionHandler:(void(^)(UATagGroups *tagGroups))completionHandler {
    __block UATagGroups *tagGroups = [UATagGroups tagGroupsWithTags:@{}];

    [self.automationEngine getSchedules:^(NSArray<UASchedule *> *schedules) {
        for (UASchedule *schedule in schedules) {
            UAInAppMessageScheduleInfo *info = (UAInAppMessageScheduleInfo *)schedule.info;
            if ([info.message.audience.tagSelector containsTagGroups]) {
                tagGroups = [tagGroups merge:info.message.audience.tagSelector.tagGroups];
            }
        }

        completionHandler(tagGroups);
    }];
}

@end

NS_ASSUME_NONNULL_END

