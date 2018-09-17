/* Copyright 2018 Urban Airship and Contributors */

#import "UALocation.h"
#import "UAComponent+Internal.h"

@class UAPreferenceDataStore;
@class UAAnalytics;

/*
 * SDK-private extensions to UALocation
 */
@interface UALocation() <CLLocationManagerDelegate>

NS_ASSUME_NONNULL_BEGIN

///---------------------------------------------------------------------------------------
/// @name Location Internal Properties
///---------------------------------------------------------------------------------------

/**
 * The location manager.
 */
@property (nonatomic, strong) CLLocationManager *locationManager;

/**
 * The data store.
 */
@property (nonatomic, strong) UAPreferenceDataStore *dataStore;

/**
 * The Urban Airship analytics.
 */
@property (nonatomic, strong) UAAnalytics *analytics;

/**
 * Flag indicating if location updates have been started or not.
 */
@property (nonatomic, assign, getter=isLocationUpdatesStarted) BOOL locationUpdatesStarted;

///---------------------------------------------------------------------------------------
/// @name Location Internal Factory
///---------------------------------------------------------------------------------------

/**
 * Factory method to create a UALocation instance.
 *
 * @param analytics UAAnalytics instance.
 * @param dataStore The preference data store.
 * @return UALocation instance.
 */
+ (instancetype)locationWithAnalytics:(UAAnalytics *)analytics dataStore:(UAPreferenceDataStore *)dataStore;

/**
 * Factory method to create a UALocation instance. Used for testing.
 *
 * @param analytics UAAnalytics instance.
 * @param dataStore The preference data store.
 * @param notificationCenter The notification center.
 * @return UALocation instance.
 */
+ (instancetype)locationWithAnalytics:(UAAnalytics *)analytics dataStore:(UAPreferenceDataStore *)dataStore notificationCenter:(NSNotificationCenter *)notificationCenter;

NS_ASSUME_NONNULL_END

@end
