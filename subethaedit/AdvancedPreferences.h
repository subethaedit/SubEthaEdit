//
//  AdvancedPreferences.h
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Sep 07 2004.
//  Copyright 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCMPreferenceModule.h"

@interface AdvancedPreferences : TCMPreferenceModule {
    IBOutlet NSButton *O_installCommandLineToolButton;
    IBOutlet NSButton *O_removeCommandLineToolButton;
    IBOutlet NSTextField *O_commandLineToolStatusTextField;
}

- (IBAction)installCommandLineTool:(id)sender;
- (IBAction)removeCommandLineTool:(id)sender;

@end
