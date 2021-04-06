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
NSString * const ScriptWrapperDidEncounterScriptErrorNotification =@"ScriptWrapperDidEncounterScriptErrorNotification";


@implementation ScriptWrapper {
    NSAppleScript *_appleScript;
    NSURL         *_URL;
    NSDictionary  *_settingsDictionary;
}

+ (id)scriptWrapperWithContentsOfURL:(NSURL *)URL {
    return [[ScriptWrapper alloc] initWithContentsOfURL:URL];
}

- (BOOL)_loadScriptAtURL:(NSURL *)URL {
    NSDictionary *errorDictionary;
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithContentsOfURL:URL error:&errorDictionary];
    if (appleScript ||
        !errorDictionary) {
        _appleScript = appleScript;
        _URL = URL;
        _settingsDictionary = nil;
        return YES;
    }
    return NO;
}

- (instancetype)initWithContentsOfURL:(NSURL *)URL {
    if ((self = [super init])) {
        if (![self _loadScriptAtURL:URL]) {
            self = nil;
        }
    }
    return self;
}

- (void)executeAndReturnError:(NSDictionary **)errorDictionary {
    [_appleScript executeAndReturnError:errorDictionary];
}

- (NSDictionary *)settingsDictionary {
    if (!_settingsDictionary) {
        NSDictionary *errorDictionary=nil;
        NSAppleEventDescriptor *ae = [_appleScript executeAppleEvent:[NSAppleEventDescriptor appleEventToCallSubroutine:@"SeeScriptSettings"] error:&errorDictionary];
		if (errorDictionary==nil) {
            _settingsDictionary = [[ae dictionaryValue] copy];
        } else {
            _settingsDictionary = @{ScriptWrapperDisplayNameSettingsKey: _URL.lastPathComponent.stringByDeletingPathExtension};
        }
    }
    return _settingsDictionary;
}

- (NSURL *)URL {
    return _URL;
}

- (void)revealSource {
    if ([_URL isFileURL]) {
		NSString *path = [_URL path];
        [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:[path stringByDeletingLastPathComponent]];
    } else {
        NSBeep();
    }
}

- (void)_delayedExecute {
    @autoreleasepool {
        BOOL isInsideAppBundle = [[_URL path] hasPrefix:[[[NSBundle mainBundle] bundleURL] path]];
        
        @synchronized ([ScriptWrapper class]) { // only one script in parallel
            
            NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
            [defaultCenter postNotificationName:ScriptWrapperWillRunScriptNotification object:self];
            
            NSDictionary<NSString *, id> *errorDictionary;
            [self executeAndReturnError:&errorDictionary];
            if (errorDictionary) {
                if (isInsideAppBundle &&
                    [errorDictionary[@"NSAppleScriptErrorMessage"] rangeOfString:@"LSOpenURLsWithRole"].location != NSNotFound)  {
                    NSURL *userScriptsDirectory = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
                    NSString *lastPathComponent = [_URL lastPathComponent];
                    NSURL *userScriptURL = [userScriptsDirectory URLByAppendingPathComponent:lastPathComponent];
                    if ([[NSFileManager defaultManager] isReadableFileAtPath:userScriptURL.path]) {
                        // Be kind and just use that script.
                        if ([self _loadScriptAtURL:userScriptURL]) {
                            NSUserScriptTask *userScript = [[NSUserScriptTask alloc] initWithURL:_URL error:nil];
                            [userScript executeWithCompletionHandler:nil];
                        }
                    } else {
                        // Help the user copy the script
                        [[NSWorkspace sharedWorkspace] selectFile:_URL.path inFileViewerRootedAtPath:[_URL.path stringByDeletingLastPathComponent]];
                        [[NSWorkspace sharedWorkspace] openURL:userScriptsDirectory];
                        id modifiedError = [errorDictionary mutableCopy];
                        // FIXME: this needs localisation
                        modifiedError[@"NSAppleScriptErrorBriefMessage"] = [NSString stringWithFormat:@"The script '%@' needs access to other applications.", lastPathComponent];
                        modifiedError[@"NSAppleScriptErrorMessage"] = [NSString stringWithFormat:@"Please copy '%@' from the opened Application Bundle script folder into the user script folder we also opened for you.", lastPathComponent];
                        // slight delay, so the SubEthaEdit error comes out on top of the rest.
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:ScriptWrapperDidEncounterScriptErrorNotification object:self userInfo:@{@"error": modifiedError}];
                        });
                    }
                } else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:ScriptWrapperDidEncounterScriptErrorNotification object:self userInfo:@{@"error": errorDictionary}];
                }
            }
            [defaultCenter postNotificationName:ScriptWrapperDidRunScriptNotification object:self userInfo:errorDictionary];
        }
        
    }
}

- (void)performScriptAction:(id)aSender {
    NSEvent *event = NSApp.currentEvent;
    if (([event type] != NSEventTypeKeyDown) &&
        ([event modifierFlags] & NSEventModifierFlagOption)) {
        [self revealSource];
    } else {
        NSURL *userScriptDirectory = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        if (userScriptDirectory && [[[_URL URLByStandardizingPath] path] hasPrefix:[[userScriptDirectory URLByStandardizingPath] path]]) {
            NSUserScriptTask *userScript = [[NSUserScriptTask alloc] initWithURL:_URL error:nil];
            [userScript executeWithCompletionHandler:nil];
        } else {
            [self performSelectorInBackground:@selector(_delayedExecute) withObject:nil];
        }
    }
}

@end
