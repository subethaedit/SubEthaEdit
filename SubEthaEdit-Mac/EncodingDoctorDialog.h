//
//  EncodingDoctorDialog.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 11.09.06.
//  Copyright 2006-2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SEEDocumentDialog.h"
#import "TCMMMOperation.h"
#import "TCMMMTransformator.h"

@interface EncodingDoctorDialog : SEEDocumentDialog {
    IBOutlet NSButton *O_cancelButton;
    IBOutlet NSButton *O_convertButton;
    IBOutlet NSButton *O_convertLossyButton;
    IBOutlet NSArrayController *O_foundErrors;
    IBOutlet NSTextField *O_descriptionTextField;
    IBOutlet NSTableView *O_tableView;
    NSStringEncoding I_encoding;
}

- (id)initWithEncoding:(NSStringEncoding)anEncoding;
- (IBAction)cancel:(id)aSender;
- (IBAction)rerunCheckAndConvert:(id)aSender;
- (IBAction)convertLossy:(id)aSender;
- (IBAction)jumpToSelection:(id)aSender; 
- (id)initialFirstResponder;
- (void)takeNoteOfOperation:(TCMMMOperation *)anOperation transformator:(TCMMMTransformator *)aTransformator;

@end

