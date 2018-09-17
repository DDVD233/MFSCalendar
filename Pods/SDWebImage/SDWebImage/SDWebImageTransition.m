/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageTransition.h"

#if SD_UIKIT || SD_MAC

#if SD_MAC
#import <QuartzCore/QuartzCore.h>
#endif

@implementation SDWebImageTransition

- (instancetype)init {
    self = [super init];
    if (self) {
        self.duration = 0.5;
    }
    return self;
}

@end

@implementation SDWebImageTransition (Conveniences)

+ (SDWebImageTransition *)fadeTransition {
    SDWebImageTransition *transition = [SDWebImageTransition new];
#if SD_UIKIT
<<<<<<< HEAD
    transition.animationOptions = UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction;
=======
    transition.animationOptions = UIViewAnimationOptionTransitionCrossDissolve;
>>>>>>> master
#else
    transition.animations = ^(__kindof NSView * _Nonnull view, NSImage * _Nullable image) {
        CATransition *trans = [CATransition animation];
        trans.type = kCATransitionFade;
        [view.layer addAnimation:trans forKey:kCATransition];
    };
#endif
    return transition;
}

+ (SDWebImageTransition *)flipFromLeftTransition {
    SDWebImageTransition *transition = [SDWebImageTransition new];
#if SD_UIKIT
<<<<<<< HEAD
    transition.animationOptions = UIViewAnimationOptionTransitionFlipFromLeft | UIViewAnimationOptionAllowUserInteraction;
=======
    transition.animationOptions = UIViewAnimationOptionTransitionFlipFromLeft;
>>>>>>> master
#else
    transition.animations = ^(__kindof NSView * _Nonnull view, NSImage * _Nullable image) {
        CATransition *trans = [CATransition animation];
        trans.type = kCATransitionPush;
        trans.subtype = kCATransitionFromLeft;
        [view.layer addAnimation:trans forKey:kCATransition];
    };
#endif
    return transition;
}

+ (SDWebImageTransition *)flipFromRightTransition {
    SDWebImageTransition *transition = [SDWebImageTransition new];
#if SD_UIKIT
<<<<<<< HEAD
    transition.animationOptions = UIViewAnimationOptionTransitionFlipFromRight | UIViewAnimationOptionAllowUserInteraction;
=======
    transition.animationOptions = UIViewAnimationOptionTransitionFlipFromRight;
>>>>>>> master
#else
    transition.animations = ^(__kindof NSView * _Nonnull view, NSImage * _Nullable image) {
        CATransition *trans = [CATransition animation];
        trans.type = kCATransitionPush;
        trans.subtype = kCATransitionFromRight;
        [view.layer addAnimation:trans forKey:kCATransition];
    };
#endif
    return transition;
}

+ (SDWebImageTransition *)flipFromTopTransition {
    SDWebImageTransition *transition = [SDWebImageTransition new];
#if SD_UIKIT
<<<<<<< HEAD
    transition.animationOptions = UIViewAnimationOptionTransitionFlipFromTop | UIViewAnimationOptionAllowUserInteraction;
=======
    transition.animationOptions = UIViewAnimationOptionTransitionFlipFromTop;
>>>>>>> master
#else
    transition.animations = ^(__kindof NSView * _Nonnull view, NSImage * _Nullable image) {
        CATransition *trans = [CATransition animation];
        trans.type = kCATransitionPush;
        trans.subtype = kCATransitionFromTop;
        [view.layer addAnimation:trans forKey:kCATransition];
    };
#endif
    return transition;
}

+ (SDWebImageTransition *)flipFromBottomTransition {
    SDWebImageTransition *transition = [SDWebImageTransition new];
#if SD_UIKIT
<<<<<<< HEAD
    transition.animationOptions = UIViewAnimationOptionTransitionFlipFromBottom | UIViewAnimationOptionAllowUserInteraction;
=======
    transition.animationOptions = UIViewAnimationOptionTransitionFlipFromBottom;
>>>>>>> master
#else
    transition.animations = ^(__kindof NSView * _Nonnull view, NSImage * _Nullable image) {
        CATransition *trans = [CATransition animation];
        trans.type = kCATransitionPush;
        trans.subtype = kCATransitionFromBottom;
        [view.layer addAnimation:trans forKey:kCATransition];
    };
#endif
    return transition;
}

+ (SDWebImageTransition *)curlUpTransition {
    SDWebImageTransition *transition = [SDWebImageTransition new];
#if SD_UIKIT
<<<<<<< HEAD
    transition.animationOptions = UIViewAnimationOptionTransitionCurlUp | UIViewAnimationOptionAllowUserInteraction;
=======
    transition.animationOptions = UIViewAnimationOptionTransitionCurlUp;
>>>>>>> master
#else
    transition.animations = ^(__kindof NSView * _Nonnull view, NSImage * _Nullable image) {
        CATransition *trans = [CATransition animation];
        trans.type = kCATransitionReveal;
        trans.subtype = kCATransitionFromTop;
        [view.layer addAnimation:trans forKey:kCATransition];
    };
#endif
    return transition;
}

+ (SDWebImageTransition *)curlDownTransition {
    SDWebImageTransition *transition = [SDWebImageTransition new];
#if SD_UIKIT
<<<<<<< HEAD
    transition.animationOptions = UIViewAnimationOptionTransitionCurlDown | UIViewAnimationOptionAllowUserInteraction;
=======
    transition.animationOptions = UIViewAnimationOptionTransitionCurlDown;
>>>>>>> master
#else
    transition.animations = ^(__kindof NSView * _Nonnull view, NSImage * _Nullable image) {
        CATransition *trans = [CATransition animation];
        trans.type = kCATransitionReveal;
        trans.subtype = kCATransitionFromBottom;
        [view.layer addAnimation:trans forKey:kCATransition];
    };
#endif
    return transition;
}

@end

#endif
