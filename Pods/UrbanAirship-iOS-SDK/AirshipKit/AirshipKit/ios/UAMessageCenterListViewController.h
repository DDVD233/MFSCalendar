/* Copyright 2018 Urban Airship and Contributors */

#import <UIKit/UIKit.h>
#import "UAMessageCenterMessageViewProtocol.h"

@class UAInboxMessage;
@class UAMessageCenterStyle;

/**
 * Default implementation of a list-style Message Center UI.
 */
@interface UAMessageCenterListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,
    UIScrollViewDelegate, UISplitViewControllerDelegate>

///---------------------------------------------------------------------------------------
/// @name Default Message Center List View Controller Properties
///---------------------------------------------------------------------------------------

/**
 * The style to apply to the list.
 */
@property (nonatomic, strong) UAMessageCenterStyle *style;

/**
 * An optional predicate for filtering messages.
 */
@property (nonatomic, strong) NSPredicate *filter;

/**
 * The view controller displaying the currently displayed message
 */
@property (nonatomic, strong) UIViewController<UAMessageCenterMessageViewProtocol> *messageViewController;

/**
 * Block that will be invoked when a message view controller receives a closeWindow message
 * from the webView.
 */
@property (nonatomic, copy) void (^closeBlock)(BOOL animated);

///---------------------------------------------------------------------------------------
/// @name Default Message Center List View Controller Message Display
///---------------------------------------------------------------------------------------

/**
 * Displays a new message, either by updating the currently displayed message or
 * by navigating to a new one.
 *
 * @param messageID The messageID of the message to load.
 */
- (void)displayMessageForID:(NSString *)messageID;

/**
 * Displays a new message, either by updating the currently displayed message or
 * by navigating to a new one.
 *
 * @param messageID The messageID of the message to load.
 * @param completion Completion block called when there is an error displaying the message
 */
- (void)displayMessageForID:(NSString *)messageID onError:(void (^)(void))completion;

@end
