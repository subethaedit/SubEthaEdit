//
//  InternetBrowserController.h
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Mar 03 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//           

#import <AppKit/AppKit.h>
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"


@interface InternetBrowserController : NSWindowController
{
    IBOutlet NSScrollView *O_scrollView;
    IBOutlet TCMMMBrowserListView  *O_browserListView;
    IBOutlet NSImageView *O_imageView;
    IBOutlet NSTextField *O_myNameTextField;
    IBOutlet NSComboBox *O_addressComboBox;
    IBOutlet NSPopUpButton *O_actionPullDownButton;

    NSMutableArray *I_data;
    NSMutableDictionary *I_resolvingHosts;
    NSMutableDictionary *I_resolvedHosts;
}

- (IBAction)connect:(id)aSender;

@end
