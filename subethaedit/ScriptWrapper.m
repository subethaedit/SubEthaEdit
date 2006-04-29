//
//  ScriptWrapper.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 04.04.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "ScriptWrapper.h"
#import "NSAppleScriptTCMAdditions.h"
#import "AppController.h"
#import "SESendProc.h"
#import "SEActiveProc.h"

NSString * const ScriptWrapperDisplayNameSettingsKey     =@"displayname";
NSString * const ScriptWrapperKeyboardShortcutSettingsKey=@"keyboardshortcut";
NSString * const ScriptWrapperToolbarIconSettingsKey     =@"toolbaricon";
NSString * const ScriptWrapperInDefaultToolbarSettingsKey=@"indefaulttoolbar";

@interface NSAppleScript (PrivateAPI)
+ (ComponentInstance) _defaultScriptingComponent;
- (OSAID) _compiledScriptID;
@end

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
//    [I_appleScript executeAndReturnError:errorDictionary];

    OSAID resultID  = kOSANullScript;
    OSAID contextID = kOSANullScript;
    OSAID scriptID  = [I_appleScript _compiledScriptID];
    ComponentInstance component = [NSAppleScript _defaultScriptingComponent];
    SESendProc   *sp=[[SESendProc   alloc] initWithComponent:component];
    SEActiveProc *ap=[[SEActiveProc alloc] initWithComponent:component];
    OSStatus err = OSAExecute(component,scriptID,contextID,kOSAModeNull,&resultID);
    AEDesc resultData;
    AECreateDesc(typeNull, NULL,0,&resultData);
    if (err==errOSAScriptError) {
        NSMutableDictionary *errorDict=[NSMutableDictionary dictionary];
        OSAScriptError(component,kOSAErrorMessage,typeChar,&resultData);
        NSAppleEventDescriptor *errorDescriptor=[[NSAppleEventDescriptor alloc] initWithAEDescNoCopy:&resultData];
        [errorDict setObject:[errorDescriptor stringValue] forKey:@"NSAppleScriptErrorMessage"];
        [errorDescriptor release];
        OSAScriptError(component,kOSAErrorNumber,typeChar,&resultData);
        errorDescriptor=[[NSAppleEventDescriptor alloc] initWithAEDescNoCopy:&resultData];
        [errorDict setObject:[NSNumber numberWithInt:[errorDescriptor int32Value]] forKey:@"NSAppleScriptErrorNumber"];
        [errorDescriptor release];
        OSAScriptError(component,kOSAErrorBriefMessage,typeChar,&resultData);
        errorDescriptor=[[NSAppleEventDescriptor alloc] initWithAEDescNoCopy:&resultData];
        [errorDict setObject:[errorDescriptor stringValue] forKey:@"NSAppleScriptErrorBriefMessage"];
        [errorDescriptor release];
        *errorDictionary = errorDict;
    }
    [ap release];
    [sp release];
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
