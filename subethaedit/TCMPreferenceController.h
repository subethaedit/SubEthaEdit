//
//  TCMPreferenceController.h
//  SubEthaEdit
//
//  Created by Martin Ott on Thu Feb 26 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>

@class TCMPreferenceModule;

@interface TCMPreferenceController : NSWindowController
{
    NSMutableDictionary *I_toolbarItems;
    NSToolbar *I_toolbar;
}

+ (void)registerPrefModule:(TCMPreferenceModule *)aModule;

@end
