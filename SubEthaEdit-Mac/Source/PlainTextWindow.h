//  PlainTextWindow.h
//  SubEthaEdit
//
//  Created by Martin Ott on 11/23/06.

#import <Cocoa/Cocoa.h>


@interface PlainTextWindow : NSWindow
@property BOOL constrainingToScreenSuspended;
@property (nonatomic, strong) IBOutlet NSView *cautionView;
@property (nonatomic, strong) IBOutlet NSTitlebarAccessoryViewController *cautionTitlebarViewController;

@property (nonatomic, readonly) BOOL hasTabGroupPeers;
@property (nonatomic, readonly) BOOL isMainWindow;

- (void)ensureTabBarVisiblity:(BOOL)shouldAlwaysBeVisible;
@end
