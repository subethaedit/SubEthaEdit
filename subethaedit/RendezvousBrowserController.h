//
//  RendezvousBrowserController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "TCMRendezvousBrowser.h"
#import "TCMMMBrowserListView.h"

@interface RendezvousBrowserController : NSWindowController {
    NSMutableArray *I_data;
    IBOutlet NSScrollView *O_scrollView;
    IBOutlet TCMMMBrowserListView  *O_browserListView;
    IBOutlet NSImageView *O_imageView;
    IBOutlet NSTextField *O_myNameTextField;
    TCMRendezvousBrowser *I_browser;
    NSMutableSet *I_foundUserIDs;
}

- (IBAction)setVisibilityByPopUpButton:(id)aSender;

@end
