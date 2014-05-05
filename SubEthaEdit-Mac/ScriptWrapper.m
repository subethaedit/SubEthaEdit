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
            } else if ([searchLocation isKindOfClass:[NSString class]]) {
                NSArray *directoryContents=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:searchLocation error:nil];
                NSEnumerator *filenames=[directoryContents objectEnumerator];
                NSString     *filename=nil;
                while ((filename=[filenames nextObject])) {
                    if ([[filename stringByDeletingPathExtension] isEqualToString:imageName]) {
                        toolbarImage = [[[NSImage alloc] initWithContentsOfFile:[searchLocation stringByAppendingPathComponent:filename]] autorelease];
                        break;
                    }
                }
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

- (void)_delayedExecute
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
    [[NSNotificationCenter defaultCenter] postNotificationName:ScriptWrapperWillRunScriptNotification object:self];
    NSDictionary *errorDictionary=nil;
    [self executeAndReturnError:&errorDictionary];
#ifdef SUBETHAEDIT
    if (errorDictionary) {
        [[AppController sharedInstance] reportAppleScriptError:errorDictionary];
    }
#endif
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
