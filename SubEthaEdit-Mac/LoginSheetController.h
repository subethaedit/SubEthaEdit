//
//  LoginSheetController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 14.05.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCMBEEP.h"

@interface LoginSheetController : NSWindowController {
    IBOutlet NSTextField *O_usernameTextField;
    IBOutlet NSSecureTextField *O_passwordTextField;
    IBOutlet NSProgressIndicator *O_progressIndicator;
    IBOutlet NSTextField *O_statusTextField;
    IBOutlet NSButton *O_cancelButton;
    IBOutlet NSButton *O_loginButton;
    
    IBOutlet NSTextField *O_textField1;
    IBOutlet NSTextField *O_textField2;
    IBOutlet NSTextField *O_textField3;
    IBOutlet NSImageView *O_imageView;

    TCMBEEPSession *_BEEPSession;
}

- (void)setBEEPSession:(TCMBEEPSession *)aBEEPSession;
- (TCMBEEPSession *)BEEPSession;
- (NSString *)peerAddressString;

- (IBAction)login:(id)aSender;
- (IBAction)cancel:(id)aSender;

@end
