//  TCMPreferenceController.h
//  SubEthaEdit
//
//  Created by Martin Ott on Thu Feb 26 2004.

#import <AppKit/AppKit.h>


@class TCMPreferenceModule;


@interface TCMPreferenceController : NSWindowController <NSToolbarDelegate, NSWindowDelegate> {
    NSMutableArray *I_toolbarItemIdentifiers;
    NSToolbar *I_toolbar;
    BOOL didShow;
}

+ (TCMPreferenceController *)sharedInstance;
+ (void)registerPrefModule:(TCMPreferenceModule *)aModule;

- (BOOL)selectPreferenceModuleWithIdentifier:(NSString *)identifier;
- (TCMPreferenceModule *)preferenceModuleWithIdentifier:(NSString *)identifier; 

@end
