#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "HKWAbstractionLayer.h"
#import "_HKWDefaultChooserArrowView.h"
#import "_HKWDefaultChooserBorderView.h"
#import "_HKWDefaultChooserView.h"
#import "HKWAttribute.h"
#import "HKWChooserViewProtocol.h"
#import "HKWControlFlowPluginProtocols.h"
#import "HKWSimplePluginProtocol.h"
#import "HKWTextView+Extras.h"
#import "HKWTextView+Plugins.h"
#import "HKWTextView+TextTransformation.h"
#import "HKWTextView.h"
#import "HKWCustomAttributes.h"
#import "HKWRoundedRectBackgroundAttributeValue.h"
#import "_HKWLayoutManager.h"
#import "_HKWPrivateConstants.h"
#import "_HKWTextView.h"
#import "HKWMentionsAttribute.h"
#import "HKWMentionsEntityProtocol.h"
#import "HKWMentionsPlugin.h"
#import "_HKWMentionsCreationStateMachine.h"
#import "_HKWMentionsPlugin.h"
#import "_HKWMentionsPrivateConstants.h"
#import "_HKWMentionsStartDetectionStateMachine.h"

FOUNDATION_EXPORT double HakawaiVersionNumber;
FOUNDATION_EXPORT const unsigned char HakawaiVersionString[];

