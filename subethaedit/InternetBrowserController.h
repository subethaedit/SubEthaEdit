//
//  InternetController.h
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Mar 03 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//           

#import <AppKit/AppKit.h>


@interface InternetController : NSWindowController
{
    IBOutlet NSTableView *O_tableView;
    IBOutlet NSImageView *O_imageView;
    IBOutlet NSTextField *O_myNameTextField;
    IBOutlet NSComboBox *O_addressComboBox;
    
    NSMutableDictionary *I_resolvingHosts;
    NSMutableDictionary *I_resolvedHosts;
}

- (IBAction)connect:(id)aSender;

@end
