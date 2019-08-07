//  PlainTextWindow.h
//  SubEthaEdit
//
//  Created by Martin Ott on 11/23/06.

#import <Cocoa/Cocoa.h>


@interface PlainTextWindow : NSWindow
@property BOOL constrainingToScreenSuspended;

- (void)ensureTabBarVisiblity:(BOOL)shouldAlwaysBeVisible;
@end
