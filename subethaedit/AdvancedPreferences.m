//
//  AdvancedPreferences.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Sep 07 2004.
//  Copyright 2004 TheCodingMonkeys. All rights reserved.
//

#import "AdvancedPreferences.h"
#import "SetupController.h"


@implementation AdvancedPreferences

- (NSImage *)icon {
    return [NSImage imageNamed:@"AdvancedPrefs"];
}

- (NSString *)iconLabel {
    return NSLocalizedString(@"AdvancedPrefsIconLabel", @"Label displayed below advanced icon and used as window title.");
}

- (NSString *)identifier {
    return @"de.codingmonkeys.subethaedit.preferences.advanced";
}

- (NSString *)mainNibName {
    return @"AdvancedPrefs";
}

- (void)mainViewDidLoad {
    id checkStatus = [[NSUserDefaults standardUserDefaults] objectForKey:@"CommandLineToolCheckStatus"];
    id lastCheckDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"CommandLineToolLastCheckDate"];
    if (checkStatus) {
        [O_commandLineToolStatusTextField setObjectValue:checkStatus];
    }
    [O_commandLineToolLastDateTextField setObjectValue:lastCheckDate];
    I_isChecking = NO;
    I_hasCancelled = NO;
}

- (void)didSelect {
    [O_commandLineToolProgressIndicator setHidden:YES];
    [O_commandLineToolLastDateTextField setHidden:NO];
}

- (void)setCommandLineStatusText:(NSString *)string {
    [[NSUserDefaults standardUserDefaults] setObject:string forKey:@"CommandLineToolCheckStatus"];
    [O_commandLineToolStatusTextField setObjectValue:string];
}

- (void)willUnselect {
    if (I_isChecking) {
        if ([I_seeCommandTask isRunning]) {
            I_hasCancelled = YES;
            [I_seeCommandTask terminate];
            [self setCommandLineStatusText:NSLocalizedString(@"Check was cancelled.", @"Status Message in Advanced Prefs")];
        }
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (void)setSeeCommandTask:(NSTask *)task {
    [I_seeCommandTask autorelease];
    I_seeCommandTask = [task retain];
}

- (IBAction)commandLineToolCheckNow:(id)sender {
    if (I_isChecking) {
        if ([I_seeCommandTask isRunning]) {
            I_hasCancelled = YES;
            [I_seeCommandTask terminate];
            [self setCommandLineStatusText:NSLocalizedString(@"Check was cancelled.", @"Status Message in Advanced Prefs")];
        }
        return;
    }

    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:SEE_TOOL_PATH isDirectory:&isDir] && !isDir) {
        I_isChecking = YES;
        I_hasCancelled = NO;
        NSTask *task = [[NSTask alloc] init];
        [self setSeeCommandTask:task];
        [I_seeCommandTask setLaunchPath:SEE_TOOL_PATH];
        [I_seeCommandTask setArguments:[NSArray arrayWithObject:@"-V"]];
        [I_seeCommandTask setStandardOutput:[NSPipe pipe]];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(didReceiveVersion:)
                                                     name:NSFileHandleReadToEndOfFileCompletionNotification
                                                   object:[[I_seeCommandTask standardOutput] fileHandleForReading]];
        [[[I_seeCommandTask standardOutput] fileHandleForReading] readToEndOfFileInBackgroundAndNotify];
        
        [O_commandLineToolCheckButton setTitle:NSLocalizedString(@"Cancel", nil)];
        [O_commandLineToolLastDateTextField setHidden:YES];
        [O_commandLineToolProgressIndicator setHidden:NO];
        [O_commandLineToolProgressIndicator startAnimation:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(didTerminate:)
                                                    name:NSTaskDidTerminateNotification
                                                  object:I_seeCommandTask];
        [I_seeCommandTask launch];
    } else {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert setMessageText:NSLocalizedString(@"The see tool couldn't be located. Would you like to install it?", @"Message text in modal dialog in advanced prefs")];
        [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"The see tool is usually installed at \"%@\".", @"Informative text in modal dialog in advanced prefs"), SEE_TOOL_PATH]];
        [alert addButtonWithTitle:NSLocalizedString(@"Install", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        [[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"\r"];
        int result = [alert runModal];
        if (result == NSAlertFirstButtonReturn) {
            BOOL success = [SetupController installCommandLineTool];
            if (!success) {
                NSAlert *alert2 = [[[NSAlert alloc] init] autorelease];
                [alert2 setAlertStyle:NSWarningAlertStyle];
                [alert2 setMessageText:NSLocalizedString(@"The installation of the see tool failed.", @"Message text in modal dialog in advanced prefs")];
                //[alert2 setInformativeText:NSLocalizedString(@"", nil)];
                [alert2 addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                (void)[alert2 runModal];
                [self setCommandLineStatusText:NSLocalizedString(@"The installation of the see tool failed.", @"Message text in modal dialog in advanced prefs")];
            } else {
                [self setCommandLineStatusText:NSLocalizedString(@"The see tool was installed.", @"Status Message in Advanced Prefs")];
            }
        } else {
            [self setCommandLineStatusText:NSLocalizedString(@"Check was cancelled.", @"Status Message in Advanced Prefs")];
        }
        
        NSCalendarDate *date = [NSCalendarDate calendarDate];
        [O_commandLineToolLastDateTextField setObjectValue:date];
        [[NSUserDefaults standardUserDefaults] setObject:date forKey:@"CommandLineToolLastCheckDate"];
    }
}

- (void)didReceiveVersion:(NSNotification *)notification {
    NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *toolVersionString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    int bundleVersion = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] intValue];
    int toolVersion = [toolVersionString intValue];
    
    if (I_hasCancelled) {
        return;
    }
    
    if (bundleVersion == toolVersion) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert setMessageText:NSLocalizedString(@"The installed see tool is up-to-date.", @"Message text in modal dialog in advanced prefs")];
        [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"You can find the see tool at \"%@\".", @"Informative text in modal dialog in advanced prefs"), SEE_TOOL_PATH]];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Remove", nil)];
        int result = [alert runModal];
        if (result == NSAlertSecondButtonReturn) {
            BOOL success = [SetupController removeCommandLineTool];
            if (!success) {
                NSAlert *alert2 = [[[NSAlert alloc] init] autorelease];
                [alert2 setAlertStyle:NSWarningAlertStyle];
                [alert2 setMessageText:NSLocalizedString(@"The see tool couldn't be removed.", @"Message text in modal dialog in advanced prefs")];
                //[alert2 setInformativeText:NSLocalizedString(@"", nil)];
                [alert2 addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                (void)[alert2 runModal];
                [self setCommandLineStatusText:NSLocalizedString(@"The see tool couldn't be removed.", @"Message text in modal dialog in advanced prefs")];
            } else {
                [self setCommandLineStatusText:NSLocalizedString(@"The see tool was removed.", @"Status Message in Advanced Prefs")];
            }
        } else {
            [self setCommandLineStatusText:NSLocalizedString(@"The see tool was up-to-date.", @"Status Message in Advanced Prefs")];
        }
    } else {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert setMessageText:NSLocalizedString(@"The installed see tool doesn't match the version of SubEthaEdit. Would you like to install the current version?", @"Message text in modal dialog in advanced prefs")];
        [alert setInformativeText:NSLocalizedString(@"SubEthaEdit works best with a see tool that matches its version.", @"Informative text in modal dialog in advanced prefs")];
        [alert addButtonWithTitle:NSLocalizedString(@"Install", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Remove", nil)];
        int result = [alert runModal];
        if (result == NSAlertFirstButtonReturn) {
            BOOL success = [SetupController installCommandLineTool];
            if (!success) {
                NSAlert *alert2 = [[[NSAlert alloc] init] autorelease];
                [alert2 setAlertStyle:NSWarningAlertStyle];
                [alert2 setMessageText:NSLocalizedString(@"The installation of the see tool failed.", @"Message text in modal dialog in advanced prefs")];
                //[alert2 setInformativeText:NSLocalizedString(@"", nil)];
                [alert2 addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                (void)[alert2 runModal];
                [self setCommandLineStatusText:NSLocalizedString(@"The installation of the see tool failed.", @"Message text in modal dialog in advanced prefs")];
            } else {
                [self setCommandLineStatusText:NSLocalizedString(@"The see tool was installed.", @"Status Message in Advanced Prefs")];
            }
        } else if (result == NSAlertSecondButtonReturn) {
            [self setCommandLineStatusText:NSLocalizedString(@"Check was cancelled.", @"Status Message in Advanced Prefs")];
        } else if (result == NSAlertThirdButtonReturn) {
            BOOL success = [SetupController removeCommandLineTool];
            if (!success) {
                NSAlert *alert2 = [[[NSAlert alloc] init] autorelease];
                [alert2 setAlertStyle:NSWarningAlertStyle];
                [alert2 setMessageText:NSLocalizedString(@"The see tool couldn't be removed.", @"Message text in modal dialog in advanced prefs")];
                //[alert2 setInformativeText:NSLocalizedString(@"", nil)];
                [alert2 addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                (void)[alert2 runModal];
                [self setCommandLineStatusText:NSLocalizedString(@"The see tool couldn't be removed.", @"Message text in modal dialog in advanced prefs")];
            } else {
                [self setCommandLineStatusText:NSLocalizedString(@"The see tool was removed.", @"Status Message in Advanced Prefs")];
            }
        }    
    }
}

- (void)didTerminate:(NSNotification *)notification {
    NSCalendarDate *date = [NSCalendarDate calendarDate];
    [O_commandLineToolLastDateTextField setObjectValue:date];
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:@"CommandLineToolLastCheckDate"];
    
    [O_commandLineToolProgressIndicator stopAnimation:self];
    [O_commandLineToolLastDateTextField setHidden:NO];
    [O_commandLineToolProgressIndicator setHidden:YES];
    [O_commandLineToolCheckButton setTitle:NSLocalizedString(@"Check Now", nil)];
    
    I_isChecking = NO;
}

@end
