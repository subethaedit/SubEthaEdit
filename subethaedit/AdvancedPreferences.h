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
    IBOutlet NSButton *O_commandLineToolCheckButton;
    IBOutlet NSTextField *O_commandLineToolStatusTextField;
    IBOutlet NSTextField *O_commandLineToolLastDateTextField;
    IBOutlet NSProgressIndicator *O_commandLineToolProgressIndicator;
    
    NSTask *I_seeCommandTask;
    NSString *I_toolVersionString;
    BOOL I_isChecking;
    BOOL I_hasCancelled;
}

- (IBAction)commandLineToolCheckNow:(id)sender;

@end
