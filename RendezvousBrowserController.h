//
//  RendezvousBrowserController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"


@interface RendezvousBrowserController : NSWindowController {
    NSMutableArray *I_data;
    IBOutlet NSScrollView *O_scrollView;
    IBOutlet TCMMMBrowserListView  *O_browserListView;
    IBOutlet NSImageView *O_imageView;
    IBOutlet NSTextField *O_myNameTextField;
    IBOutlet NSPopUpButton *O_actionPullDownButton;
    IBOutlet NSPopUpButton *O_statusPopUpButton;
    NSMutableSet *I_userIDsInRendezvous;
    
    NSMenu *I_contextMenu;
}

+ (RendezvousBrowserController *)sharedInstance;

- (IBAction)setVisibilityByMenuItem:(id)aSender;

@end
