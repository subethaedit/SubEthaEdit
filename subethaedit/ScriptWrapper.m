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
NSString * const ScriptWrapperShortDisplayNameSettingsKey=@"shortdisplayname";
NSString * const ScriptWrapperToolbarToolTipSettingsKey  =@"toolbartooltip";
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
    [I_appleScript executeAndReturnError:errorDictionary];
/*
    OSAID resultID  = kOSANullScript;
    OSAID contextID = kOSANullScript;
    OSAID scriptID  = [I_appleScript _compiledScriptID];
    ComponentInstance component = OpenDefaultComponent( kOSAComponentType, typeAppleScript );
    SESendProc   *sp=[[SESendProc   alloc] initWithComponent:component];
    SEActiveProc *ap=[[SEActiveProc alloc] initWithComponent:component];
    FSRef fsRef;
    
    if (!CFURLGetFSRef((CFURLRef)I_URL, &fsRef)) {
        NSBeep();
        NSLog(@"mist, fsref ging nicht");
    }
    OSStatus err = noErr;
    err = OSALoadFile(component,&fsRef,NULL,0,&scriptID);
    if (err==noErr) {
        err = OSAExecute(component,scriptID,contextID,kOSAModeNull,&resultID);
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
    } else {
        NSLog(@"OSALoadFile did fail");
    }
    */
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

- (NSToolbarItem *)toolbarItemWithImageSearchLocations:(NSArray *)anImageSearchLocationsArray identifierAddition:(NSString *)anAddition {
    NSDictionary *settingsDictionary=[self settingsDictionary];
    NSString *imageName=[settingsDictionary objectForKey:ScriptWrapperToolbarIconSettingsKey];
    if (imageName) {
        NSImage *toolbarImage = nil;
        NSEnumerator *searchLocations=[anImageSearchLocationsArray objectEnumerator];
        id searchLocation = nil;
        while (!toolbarImage && (searchLocation=[searchLocations nextObject])) {
            if ([searchLocation isKindOfClass:[NSBundle class]]) {
                NSString *imagePath = [searchLocation pathForImageResource:imageName];
                if (imagePath) toolbarImage = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
            }
        }
        if (!toolbarImage) toolbarImage = [NSImage imageNamed:imageName];
        if (!toolbarImage) NSLog(@"Image for script: %@ was not found.", [I_URL path]);
        if (toolbarImage) {
            NSString *toolbarItemIdentifier = [NSString stringWithFormat:@"%@%@ToolbarItemIdentifier", [[I_URL path] lastPathComponent], anAddition];
            NSString *displayName = [settingsDictionary objectForKey:ScriptWrapperDisplayNameSettingsKey]?[settingsDictionary objectForKey:ScriptWrapperDisplayNameSettingsKey]:[[[I_URL path] lastPathComponent] stringByDeletingPathExtension];

            NSToolbarItem *item=[[[NSToolbarItem alloc] initWithItemIdentifier:toolbarItemIdentifier] autorelease];
            [item setImage:toolbarImage];
            [item setLabel:[settingsDictionary objectForKey:ScriptWrapperShortDisplayNameSettingsKey]?[settingsDictionary objectForKey:ScriptWrapperShortDisplayNameSettingsKey]:displayName];
            [item setPaletteLabel:[item label]];
            [item setTarget:self];
            [item setAction:@selector(performScriptAction:)];
            if ([settingsDictionary objectForKey:ScriptWrapperToolbarToolTipSettingsKey]) {
                [item setToolTip:[settingsDictionary objectForKey:ScriptWrapperToolbarToolTipSettingsKey]];
            }
            return item;
        }
    }
    return nil;
}


- (void)revealSource {
    if ([I_URL isFileURL]) {
        [[NSWorkspace sharedWorkspace] selectFile:[I_URL path] inFileViewerRootedAtPath:nil];
    } else {
        NSBeep();
    }
}

- (void)performScriptAction:(id)aSender {
    if (([[NSApp currentEvent] type]!=NSKeyDown) &&
        (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) ||
         (GetCurrentKeyModifiers() & optionKey)) ) {
        [self revealSource];
    } else {
        NSDictionary *errorDictionary=nil;
        [self executeAndReturnError:&errorDictionary];
        if (errorDictionary) {
            [[AppController sharedInstance] reportAppleScriptError:errorDictionary];
        }
    }

}

@end
