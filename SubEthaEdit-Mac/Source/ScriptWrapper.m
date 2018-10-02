//  ScriptWrapper.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 04.04.06.

#import "ScriptWrapper.h"
#import "NSAppleScriptTCMAdditions.h"
#import "AppController.h"


NSString * const ScriptWrapperDisplayNameSettingsKey     =@"displayname";
NSString * const ScriptWrapperShortDisplayNameSettingsKey=@"shortdisplayname";
NSString * const ScriptWrapperToolbarToolTipSettingsKey  =@"toolbartooltip";
NSString * const ScriptWrapperKeyboardShortcutSettingsKey=@"keyboardshortcut";
NSString * const ScriptWrapperToolbarIconSettingsKey     =@"toolbaricon";
NSString * const ScriptWrapperInDefaultToolbarSettingsKey=@"indefaulttoolbar";
NSString * const ScriptWrapperInContextMenuSettingsKey   =@"incontextmenu";

NSString * const ScriptWrapperWillRunScriptNotification=@"ScriptWrapperWillRunScriptNotification";
NSString * const ScriptWrapperDidRunScriptNotification =@"ScriptWrapperDidRunScriptNotification";


@implementation ScriptWrapper

+ (id)scriptWrapperWithContentsOfURL:(NSURL *)anURL {
    return [[[ScriptWrapper alloc] initWithContentsOfURL:anURL] autorelease];
}

- (id)initWithContentsOfURL:(NSURL *)anURL {
    if ((self=[super init])) {
        NSDictionary *errorDictionary=nil;
        I_appleScript = [[NSAppleScript alloc] initWithContentsOfURL:anURL error:&errorDictionary];
        if (!I_appleScript || errorDictionary) {
            [self release];
			self = nil;
            return self;
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
            I_settingsDictionary = @{ScriptWrapperDisplayNameSettingsKey: I_URL.lastPathComponent.stringByDeletingPathExtension};
        }
    }
    return I_settingsDictionary;
}

- (NSURL *)URL {
    return I_URL;
}

- (void)revealSource {
    if ([I_URL isFileURL]) {
		NSString *path = [I_URL path];
        [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:[path stringByDeletingLastPathComponent]];
    } else {
        NSBeep();
    }
}

- (void)_delayedExecute
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
    [[NSNotificationCenter defaultCenter] postNotificationName:ScriptWrapperWillRunScriptNotification object:self];
    NSDictionary *errorDictionary=nil;
    [self executeAndReturnError:&errorDictionary];
    if (errorDictionary) {
        [[AppController sharedInstance] reportAppleScriptError:errorDictionary];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ScriptWrapperDidRunScriptNotification object:self userInfo:errorDictionary];
	[pool drain];
}

- (void)performScriptAction:(id)aSender {
    if (([[NSApp currentEvent] type] != NSKeyDown) &&
        ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)) {
        [self revealSource];
    } else {
        NSURL *userScriptDirectory = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        if (userScriptDirectory && [[[I_URL URLByStandardizingPath] path] hasPrefix:[[userScriptDirectory URLByStandardizingPath] path]])
        {
            NSUserScriptTask *userScript = [[[NSUserScriptTask alloc] initWithURL:I_URL error:nil] autorelease];
            [userScript executeWithCompletionHandler:nil];
        }
        else
        {
            [self performSelectorInBackground:@selector(_delayedExecute) withObject:nil];
        }
    }
}

@end
