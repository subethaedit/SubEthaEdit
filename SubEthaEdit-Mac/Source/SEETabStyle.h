//  SEETabStyle.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 29.01.14.

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <PSMTabBarControl/PSMTabStyle.h>

@interface SEETabStyle : NSObject <PSMTabStyle>
+ (CGFloat)desiredTabBarControlHeight;
@end
