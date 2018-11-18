//  ScriptWrapper.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 04.04.06.

#import <Cocoa/Cocoa.h>

extern NSString * const ScriptWrapperDisplayNameSettingsKey;
extern NSString * const ScriptWrapperShortDisplayNameSettingsKey;
extern NSString * const ScriptWrapperToolbarToolTipSettingsKey  ;
extern NSString * const ScriptWrapperKeyboardShortcutSettingsKey;
extern NSString * const ScriptWrapperToolbarIconSettingsKey;
extern NSString * const ScriptWrapperInDefaultToolbarSettingsKey;
extern NSString * const ScriptWrapperInContextMenuSettingsKey;

extern NSString * const ScriptWrapperWillRunScriptNotification;
extern NSString * const ScriptWrapperDidRunScriptNotification;


@interface ScriptWrapper : NSObject

+ (id)scriptWrapperWithContentsOfURL:(NSURL *)URL;

- (id)initWithContentsOfURL:(NSURL *)URL;
- (void)executeAndReturnError:(NSDictionary **)errorDictionary;
- (NSDictionary *)settingsDictionary;
- (void)revealSource;
- (IBAction)performScriptAction:(id)aSender;
- (NSURL *)URL;
@end
