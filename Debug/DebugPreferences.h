//
//  DebugPreferences.h
//  SubEthaEdit
//
//  Created by Martin Ott on Thu Feb 26 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#ifndef TCM_NO_DEBUG


#import <Foundation/Foundation.h>
#import "TCMPreferenceModule.h"


@interface DebugPreferences : TCMPreferenceModule
{
    NSMutableArray *logDomains;
    NSMutableArray *levels;
    
    IBOutlet NSButton *toggleDebugMenuCheckBox;
}

- (IBAction)toggleDebugMenu:(id)sender;

@end


#endif