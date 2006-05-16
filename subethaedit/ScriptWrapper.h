//
//  ScriptWrapper.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 04.04.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const ScriptWrapperDisplayNameSettingsKey;
extern NSString * const ScriptWrapperShortDisplayNameSettingsKey;
extern NSString * const ScriptWrapperToolbarToolTipSettingsKey  ;
extern NSString * const ScriptWrapperKeyboardShortcutSettingsKey;
extern NSString * const ScriptWrapperToolbarIconSettingsKey;
extern NSString * const ScriptWrapperInDefaultToolbarSettingsKey;

extern NSString * const ScriptWrapperWillRunScriptNotification;
extern NSString * const ScriptWrapperDidRunScriptNotification;


@interface ScriptWrapper : NSObject {
    NSAppleScript *I_appleScript;
    NSURL         *I_URL;
    NSDictionary  *I_settingsDictionary;
}

+ (id)scriptWrapperWithContentsOfURL:(NSURL *)anURL;

- (id)initWithContentsOfURL:(NSURL *)anURL;
- (NSToolbarItem *)toolbarItemWithImageSearchLocations:(NSArray *)anImageSearchLocationsArray identifierAddition:(NSString *)anAddition;
- (void)executeAndReturnError:(NSDictionary **)errorDictionary;
- (NSDictionary *)settingsDictionary;
- (void)revealSource;
- (IBAction)performScriptAction:(id)aSender;

@end
