//  URLBubbleWindow.h
//  SubEthaEdit
//
//  Created by dom on 13.07.09.

#import <Cocoa/Cocoa.h>
#import "MAAttachedWindow.h"


@interface URLBubbleWindow : MAAttachedWindow

@property (readwrite, strong) IBOutlet NSView *openURLViewOutlet;
@property (nonatomic, strong) NSURL *URLToOpen;

+ (URLBubbleWindow *)sharedURLBubbleWindow;

- (instancetype)initAsBubble;

- (IBAction)openURLAction:(id)aSender;
- (IBAction)hideWindow:(id)aSender;
- (void)hideIfNecessary;

- (void)setPosition:(NSPoint)inPosition inWindow:(NSWindow *)inWindow;
- (void)setVisible:(BOOL)inVisible animated:(BOOL)inAnimated;

@end
