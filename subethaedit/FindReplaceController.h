//
//  FindReplaceController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Apr 23 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FindReplaceController : NSObject {
    IBOutlet NSPanel *O_findPanel;
    IBOutlet NSPanel *O_gotoPanel;
    IBOutlet NSTextField *O_gotoLineTextField;
}

+ (FindReplaceController *)sharedInstance;

- (NSPanel *)findPanel;
- (NSPanel *)gotoPanel;

- (NSTextView *)textViewToSearchIn;

- (IBAction)orderFrontGotoPanel:(id)aSender;
- (IBAction)gotoLine:(id)aSender;
- (IBAction)gotoLineAndClosePanel:(id)aSender;

@end
