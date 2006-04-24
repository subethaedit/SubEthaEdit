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
        I_tasks = [NSMutableSet new];
    }
    return self;
}

- (void)dealloc {
    [I_settingsDictionary release];
    [I_URL release];
    [I_appleScript release];
    [I_tasks release];
    [super dealloc];
}

- (void)executeAndReturnError:(NSDictionary **)errorDictionary {
//    [I_appleScript executeAndReturnError:errorDictionary];
    NSTask *task = [NSTask new];
    [task setLaunchPath:@"/usr/bin/osascript"]; 
    [task setArguments:[NSArray arrayWithObject:[I_URL path]]];
    [task setStandardError:[NSPipe pipe]];
    [task setStandardOutput:[NSPipe pipe]];
    [task launch];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskDidTerminate:) name:NSTaskDidTerminateNotification object:task];
    [I_tasks addObject:task];
    [task release];
}

- (void)taskDidTerminate:(NSNotification *)aNotification {
    NSTask *task = [aNotification object];
    NSLog(@"Termination status: %d", [task terminationStatus]);
    if ([task terminationStatus]!=0) {
        NSString *errorString = [[[NSString alloc] initWithData:[[[task standardError] fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease];
        if (!errorString) errorString=@"Haha";
        NSDictionary *errorDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"AppleScript Error occured",@"NSAppleScriptErrorBriefMessage",
        errorString,@"NSAppleScriptErrorMessage",
        [NSNumber numberWithInt:-42],@"NSAppleScriptErrorNumber",
        nil];
        [[AppController sharedInstance] reportAppleScriptError:errorDictionary];
    }
    [[task retain] autorelease];
    [I_tasks removeObject:task];
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
