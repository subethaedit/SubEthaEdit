//
//  AboutPanelController.h
//  SubEthaEdit
//
//  Created by Martin Ott on Thu May 13 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface AboutPanelController : NSWindowController {
    IBOutlet NSImageView *O_appIconView;
    IBOutlet NSTextField *O_legalTextField;
    IBOutlet NSTextField *O_versionField;
    IBOutlet NSTextField *O_ogreVersionField;
    IBOutlet NSTextField *O_licenseeLabel;
    IBOutlet NSTextField *O_licenseeNameField;
    IBOutlet NSTextField *O_licenseeOrganizationField;
}

@end
