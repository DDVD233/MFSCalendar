//
//  BInterfaceManager.h
//  Pods
//
//  Created by Benjamin Smiley-andrews on 14/09/2016.
//
//

#import <Foundation/Foundation.h>

@protocol PInterfaceFacade;

@interface BInterfaceManager : NSObject

+(BInterfaceManager *) sharedManager;
-(id<PInterfaceFacade>) a;

@end
