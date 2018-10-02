//
//  AdvancedPreferences.h
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Sep 07 2004.
//  Copyright 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCMPreferenceModule.h"

#define SEE_TOOL_PATH    @"/usr/bin/see"
#define SEE_MANPAGE_PATH @"/usr/share/man/man1/see.1"

@interface AdvancedPreferences : TCMPreferenceModule

@property (nonatomic, weak) IBOutlet NSButton *O_disableScreenFontsButton;
@property (nonatomic, weak) IBOutlet NSButton *O_synthesiseFontsButton;

- (IBAction)changeDisableScreenFonts:(id)aSender;
- (IBAction)changeSynthesiseFonts:(id)aSender;

@end
