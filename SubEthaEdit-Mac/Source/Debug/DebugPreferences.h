//  DebugPreferences.h
//  SubEthaEdit
//
//  Created by Martin Ott on Thu Feb 26 2004.

#ifndef TCM_NO_DEBUG


#import <Foundation/Foundation.h>
#import "TCMPreferenceModule.h"


@interface DebugPreferences : TCMPreferenceModule
{
    NSMutableArray *logDomains;
    NSMutableArray *levels;
    
    IBOutlet NSButton *toggleDebugMenuCheckBox;
	IBOutlet NSButton *toggleBEEPLoggingCheckBox;
}

- (IBAction)toggleDebugMenu:(id)sender;
- (IBAction)toggleBEEPLogging:(id)sender;

@end


#endif
