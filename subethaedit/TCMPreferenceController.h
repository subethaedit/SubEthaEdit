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
    NSMutableArray *I_toolbarItemIdentifiers;
    NSToolbar *I_toolbar;
    NSString *I_selectedItemIdentifier;
    NSView *I_contentView;
}

+ (void)registerPrefModule:(TCMPreferenceModule *)aModule;

@end
