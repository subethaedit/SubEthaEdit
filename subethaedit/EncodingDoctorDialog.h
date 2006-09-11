//
//  EncodingDoctorDialog.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 11.09.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SEEDocumentDialog.h"

@interface EncodingDoctorDialog : SEEDocumentDialog {
    IBOutlet NSButton *O_cancelButton;
    IBOutlet NSButton *O_convertButton;
    IBOutlet NSButton *O_convertLossyButton;
}

- (IBAction)cancel:(id)aSender;

@end
