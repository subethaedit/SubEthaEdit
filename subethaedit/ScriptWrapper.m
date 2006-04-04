//
//  ScriptWrapper.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 04.04.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "ScriptWrapper.h"
#import "NSAppleScriptTCMAdditions.h"

NSString * const ScriptWrapperDisplayNameSettingsKey     =@"displayname";
NSString * const ScriptWrapperKeyboardShortcutSettingsKey=@"keyboardshortcut";
NSString * const ScriptWrapperToolbarIconSettingsKey     =@"toolbaricon";
NSString * const ScriptWrapperInDefaultToolbarSettingsKey=@"indefaulttoolbar";


@implementation ScriptWrapper

+ (id)scriptWrapperWithContentsOfURL:(NSURL *)anURL {
    return [[ScriptWrapper alloc] initWithContentsOfURL:anURL];
}

- (id)initWithContentsOfURL:(NSURL *)anURL {
    if ((self=[super init])) {
        NSDictionary *errorDictionary=nil;
        I_appleScript = [[NSAppleScript alloc] initWithContentsOfURL:anURL error:&errorDictionary];
        if (!I_appleScript || errorDictionary) {
            [super dealloc];
            return nil;
        }
        I_URL = [anURL copy];
    }
    return self;
}

- (void)dealloc {
    [I_settingsDictionary release];
    [I_URL release];
    [I_appleScript release];
    [super dealloc];
}

- (void)executeAndReturnError:(NSDictionary **)errorDictionary {
    [I_appleScript executeAndReturnError:errorDictionary];
}

- (NSDictionary *)settingsDictionary {
    if (!I_settingsDictionary) {
        NSDictionary *errorDictionary=nil;
        NSAppleEventDescriptor *ae = [I_appleScript executeAppleEvent:[NSAppleEventDescriptor appleEventToCallSubroutine:@"SeeScriptSettings"] error:&errorDictionary];
        if (errorDictionary==nil) {
            I_settingsDictionary = [[ae dictionaryValue] copy];
        } else {
            I_settingsDictionary = [[NSDictionary alloc] init];
        }
    }
    return I_settingsDictionary;
}

- (void)revealSource {
    if ([I_URL isFileURL]) {
        [[NSWorkspace sharedWorkspace] selectFile:[I_URL path] inFileViewerRootedAtPath:nil];
    } else {
        NSBeep();
    }
}

@end
