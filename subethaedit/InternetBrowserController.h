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
    IBOutlet NSPopUpButton *O_statusPopUpButton;

    NSMutableArray *I_data;
    NSMutableArray *I_comboBoxItems;
    NSMutableDictionary *I_resolvingHosts;
    NSMutableDictionary *I_resolvedHosts;
}

+ (InternetBrowserController *)sharedInstance;

- (NSMutableArray *)comboBoxItems;
- (void)setComboBoxItems:(NSMutableArray *)anArray;

- (IBAction)connect:(id)aSender;
- (IBAction)setVisibilityByMenuItem:(id)aSender;

- (void)connectToAddress:(NSString *)address;

@end
