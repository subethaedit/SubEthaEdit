//
//  FindReplaceController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Apr 23 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "FindReplaceController.h"
#import "PlainTextWindowController.h"

static FindReplaceController *sharedInstance=nil;


@implementation FindReplaceController

+ (FindReplaceController *)sharedInstance {
    return sharedInstance;
}

- (id)init {
    if (sharedInstance) {
        [super dealloc];
        return sharedInstance;
    }
    
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)loadUI {
    if (!O_findPanel) {
        if (![NSBundle loadNibNamed:@"FindReplace" owner:self]) {
            NSLog(@"Failed to load FindReplace.nib");
            NSBeep();
        }
    }
}

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidActivate:) name:NSApplicationDidBecomeActiveNotification object:[NSApplication sharedApplication]];
}

- (NSPanel *)findPanel {
    if (!O_findPanel) [self loadUI];
    return O_findPanel;
}
- (NSPanel *)gotoPanel {
    if (!O_findPanel) [self loadUI];
    return O_gotoPanel;
}

- (NSTextView *)textViewToSearchIn {
    id obj = [[NSApp mainWindow] firstResponder];
    return (obj && [obj isKindOfClass:[NSTextView class]]) ? obj : nil;
}

- (IBAction)orderFrontGotoPanel:(id)aSender {
    NSPanel *panel = [self gotoPanel];
    [[O_gotoLineTextField cell] setSendsActionOnEndEditing:NO];
    [O_gotoLineTextField selectText:nil];
    [panel makeKeyAndOrderFront:nil];    
    [[O_gotoLineTextField cell] setSendsActionOnEndEditing:YES];
}

- (IBAction)gotoLine:(id)aSender {
    NSTextView *textView = [self textViewToSearchIn];
    [(PlainTextWindowController *)[[textView window] windowController] gotoLine:[O_gotoLineTextField intValue]];

}

- (IBAction)gotoLineAndClosePanel:(id)aSender {
    [self gotoLine:aSender];
    [[self gotoPanel] orderOut:self];   
}


#pragma mark -
#pragma mark ### Notification handling ###

- (void)applicationDidActivate:(NSNotification *)aNotification {
    // take string from find pasteboard
}

@end
