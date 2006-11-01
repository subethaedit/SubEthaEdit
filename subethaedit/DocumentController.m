//
//  DocumentController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Mar 25 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import "DocumentController.h"
#import "TCMMMSession.h"
#import "PlainTextDocument.h"
#import "EncodingManager.h"
#import "DocumentModeManager.h"
#import "AppController.h"
#import "TCMMMPresenceManager.h"
#import "TCMPreferenceController.h"
#import "TCMPreferenceModule.h"
#import "StylePreferences.h"
#import "TextStorage.h"
#import "NSSavePanelTCMAdditions.h"
#import "MoreSecurity.h"
#import "PlainTextWindowController.h"


@interface DocumentController (DocumentControllerPrivateAdditions)

- (void)setModeIdentifierFromLastRunOpenPanel:(NSString *)modeIdentifier;
- (void)setEncodingFromLastRunOpenPanel:(NSStringEncoding)stringEncoding;

@end


@implementation DocumentController (DocumentControllerPrivateAdditions)

- (void)setEncodingFromLastRunOpenPanel:(NSStringEncoding)stringEncoding {
    I_encodingFromLastRunOpenPanel = stringEncoding;
}

- (void)setModeIdentifierFromLastRunOpenPanel:(NSString *)modeIdentifier {
    [I_modeIdentifierFromLastRunOpenPanel release];
    I_modeIdentifierFromLastRunOpenPanel = [modeIdentifier copy];
}

- (void)openModeFile:(NSString *)fileName
{
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Opening mode file: %@", fileName);
    NSBundle *modeBundle = [NSBundle bundleWithPath:fileName];
    NSString *versionString = [modeBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *name = [NSString stringWithFormat:@"%@ (%@)", [fileName lastPathComponent], versionString];
    [O_modeInstallerMessageTextField setObjectValue:[NSString stringWithFormat:NSLocalizedString(@"Do you want to install the mode \"%@\"?", nil), name]];
    [O_modeInstallerDomainMatrix selectCellAtRow:0 column:0];

    NSString *modeIdentifier = [modeBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForIdentifier:modeIdentifier];
    if (mode) {
        NSBundle *installedModeBundle = [mode bundle];
        NSString *versionStringOfInstalledMode = [installedModeBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSString *installedModeFileName = [installedModeBundle bundlePath];
        
        OSErr err = noErr;
        FSRef folderRef;
        NSString *userDomainPath = nil;
        NSString *localDomainPath = nil;
        NSString *networkDomainPath = nil;
        
        err = FSFindFolder(kUserDomain, kApplicationSupportFolderType, kDontCreateFolder, &folderRef);
        if (err == noErr)
            userDomainPath = [(NSURL *)CFURLCreateFromFSRef(kCFAllocatorSystemDefault, &folderRef) path];

        err = FSFindFolder(kLocalDomain, kApplicationSupportFolderType, kDontCreateFolder, &folderRef);
        if (err == noErr)
            localDomainPath = [(NSURL *)CFURLCreateFromFSRef(kCFAllocatorSystemDefault, &folderRef) path];
            
        err = FSFindFolder(kNetworkDomain, kApplicationSupportFolderType, kDontCreateFolder, &folderRef);
        if (err == noErr)
            networkDomainPath = [(NSURL *)CFURLCreateFromFSRef(kCFAllocatorSystemDefault, &folderRef) path];
            
        short domain;
        BOOL isKnownDomain = YES;
        if (userDomainPath != nil && [installedModeFileName hasPrefix:userDomainPath]) {
            domain = kUserDomain;
        } else if (localDomainPath != nil && [installedModeFileName hasPrefix:localDomainPath]) {
            domain = kLocalDomain;
        } else if (networkDomainPath != nil && [installedModeFileName hasPrefix:networkDomainPath]) {
            domain = kNetworkDomain;
        } else {
            isKnownDomain = NO;
        }
        
        NSString *installedModeName = [NSString stringWithFormat:@"%@ (%@)", [installedModeFileName lastPathComponent], versionStringOfInstalledMode];
        NSString *informativeText = [NSString stringWithFormat:NSLocalizedString(@"Mode \"%@\" is already installed in \"%@\".", nil), installedModeName, installedModeFileName];

        if (!isKnownDomain || domain == kNetworkDomain || domain == kLocalDomain) {
            informativeText = [informativeText stringByAppendingFormat:@" %@", NSLocalizedString(@"You will override the installed mode.", nil)];
        } else if (domain == kUserDomain) {
            informativeText = [informativeText stringByAppendingFormat:@" %@", NSLocalizedString(@"You will replace the installed mode.", nil)];
        }

        [O_modeInstallerInformativeTextField setObjectValue:informativeText];
    } else {
        [O_modeInstallerInformativeTextField setObjectValue:@""];
    }

    I_currentModeFileName = fileName;
    int result = [NSApp runModalForWindow:O_modeInstallerPanel];
    [O_modeInstallerPanel orderOut:self];
    I_currentModeFileName = nil;
    if (result == NSRunStoppedResponse) {
        BOOL success = NO;

        short domain;
        int tag = [[O_modeInstallerDomainMatrix selectedCell] tag];
        if (tag == 0) {
            domain = kUserDomain;
        } else if (tag == 1) {
            domain = kLocalDomain;
        }
        
        // Determine destination path and copy mode package
        OSErr err = noErr;
        FSRef folderRef;
        err = FSFindFolder(domain, kApplicationSupportFolderType, kDontCreateFolder, &folderRef);
        if (err == noErr) {
            CFURLRef appSupportURL = CFURLCreateFromFSRef(kCFAllocatorSystemDefault, &folderRef);
            NSString *destination = [(NSURL *)appSupportURL path];
            destination = [destination stringByAppendingPathComponent:@"SubEthaEdit"];
            destination = [destination stringByAppendingPathComponent:@"Modes"];
            destination = [destination stringByAppendingPathComponent:[fileName lastPathComponent]];
            DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Mode installation path: %@", destination);
            
            if (![fileName isEqualToString:destination]) {
                if (domain == kUserDomain) {
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    if ([fileManager fileExistsAtPath:destination]) {
                        (void)[fileManager removeFileAtPath:destination handler:self];
                    }
                    success = [fileManager copyPath:fileName toPath:destination handler:self];
                } else {
                    OSStatus err;
                    CFURLRef tool = NULL;
                    AuthorizationRef auth = NULL;
                    NSDictionary *request = nil;
                    NSDictionary *response = nil;
                    BOOL result = NO;


                    err = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &auth);
                    if (err == noErr) {
                        static const char *kRightName = "de.codingmonkeys.SubEthaEdit.HelperTool";
                        static const AuthorizationFlags kAuthFlags = kAuthorizationFlagDefaults 
                                                                   | kAuthorizationFlagInteractionAllowed
                                                                   | kAuthorizationFlagExtendRights
                                                                   | kAuthorizationFlagPreAuthorize;
                        AuthorizationItem   right  = { kRightName, 0, NULL, 0 };
                        AuthorizationRights rights = { 1, &right };

                        err = AuthorizationCopyRights(auth, &rights, kAuthorizationEmptyEnvironment, kAuthFlags, NULL);
                    }
                    
                    if (err == noErr) {
                        err = MoreSecCopyHelperToolURLAndCheckBundled(
                            CFBundleGetMainBundle(), 
                            CFSTR("SubEthaEditHelperToolTemplate"), 
                            kApplicationSupportFolderType, 
                            CFSTR("SubEthaEdit"), 
                            CFSTR("SubEthaEditHelperTool"), 
                            &tool);

                        // If the home directory is on an volume that doesn't support 
                        // setuid root helper tools, ask the user whether they want to use 
                        // a temporary tool.
                        
                        if (err == kMoreSecFolderInappropriateErr) {
                            err = MoreSecCopyHelperToolURLAndCheckBundled(
                                CFBundleGetMainBundle(), 
                                CFSTR("SubEthaEditHelperToolTemplate"), 
                                kTemporaryFolderType, 
                                CFSTR("SubEthaEdit"), 
                                CFSTR("SubEthaEditHelperTool"), 
                                &tool);
                        }
                    }

                    // Create the request dictionary for copying the mode

                    if (err == noErr) {
                        request = [NSDictionary dictionaryWithObjectsAndKeys:
                                            @"CopyFiles", @"CommandName",
                                            fileName, @"SourceFile",
                                            destination, @"TargetFile",
                                            //targetAttrs, @"TargetAttributes",
                                            nil];
                    }

                    // Go go gadget helper tool!

                    if (err == noErr) {
                        err = MoreSecExecuteRequestInHelperTool(tool, auth, (CFDictionaryRef)request, (CFDictionaryRef *)(&response));
                    }
                    
                    // Extract information from the response.
                    
                    if (err == noErr) {
                        //NSLog(@"response: %@", response);

                        err = MoreSecGetErrorFromResponse((CFDictionaryRef)response);
                        if (err == noErr) {
                            result = YES;
                            success = YES;
                        }
                    }
                    
                    // Clean up after second call of helper tool.
                    if (response) {
                        [response release];
                    }


                    CFQRelease(tool);
                    if (auth != NULL) {
                        (void)AuthorizationFree(auth, kAuthorizationFlagDestroyRights);
                    }
                }
            } else {
                success = YES;
            }
        }
        
        [[DocumentModeManager sharedInstance] reloadDocumentModes:self];
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSInformationalAlertStyle];
        if (success) {
            [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"The mode \"%@\" has been installed successfully.", nil), name]];       
        } else {
            [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Installation of mode \"%@\" failed.", nil), name]];
        }
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        (void)[alert runModal];
        [alert release];
    }
}

- (void)openDirectory:(NSString *)fileName
{
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Opening directory: %@", fileName);
}

static NSString *tempFileName() {
    static int sequenceNumber = 0;
    NSString *origPath = [@"/tmp" stringByAppendingPathComponent:@"see"];
    NSString *name;
    do {
        sequenceNumber++;
        name = [NSString stringWithFormat:@"SEE-%d-%d-%d", [[NSProcessInfo processInfo] processIdentifier], (int)[NSDate timeIntervalSinceReferenceDate], sequenceNumber];
        name = [[origPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:name];
    } while ([[NSFileManager defaultManager] fileExistsAtPath:name]);
    return name;
}

@end


#pragma mark -

@implementation DocumentController

+ (DocumentController *)sharedInstance {
    return (DocumentController *)[NSDocumentController sharedDocumentController];
}

- (id)init {
    self = [super init];
    if (self) {
        I_isOpeningUntitledDocument = NO;
        I_fileNamesFromLastRunOpenPanel = [NSMutableArray new];
        I_propertiesForOpenedFiles = [NSMutableDictionary new];
        I_suspendedSeeScriptCommands = [NSMutableDictionary new];
        I_waitingDocuments = [NSMutableDictionary new];
        I_refCountsOfSeeScriptCommands = [NSMutableDictionary new];
        I_pipingSeeScriptCommands = [NSMutableArray new];
        
        I_windowControllers = [NSMutableArray new];
        I_documentsWithPendingDisplay = [NSMutableArray new];
    }
    return self;
}

// actually never gets called - as any other top level nib object isn't dealloced...
- (void)dealloc {
    [I_modeIdentifierFromLastRunOpenPanel release];
    [I_fileNamesFromLastRunOpenPanel release];
    [I_propertiesForOpenedFiles release];
    [I_suspendedSeeScriptCommands release];
    [I_waitingDocuments release];
    [I_refCountsOfSeeScriptCommands release];
    [I_pipingSeeScriptCommands release];
    
    [I_documentsWithPendingDisplay release];
    [I_windowControllers release];
    
    [super dealloc];
}

- (void)displayPendingDocuments
{
    // How many documents need displaying?
    unsigned int documentCount = [I_documentsWithPendingDisplay count];
    if (documentCount == 1) {
        // Just one. Do what NSDocumentController would have done if this class didn't override -openDocumentWithContentsOfURL:display:error:.
        NSDocument *document = [I_documentsWithPendingDisplay objectAtIndex:0];
        [document makeWindowControllers];
        [document showWindows];
        [(PlainTextDocument *)document handleOpenDocumentEvent];
    } else if (documentCount > 0) {
        // More than one. Instantiate a window controller that can display all of them.
        PlainTextWindowController *windowController = [[PlainTextWindowController alloc] init];
        [I_windowControllers addObject:windowController];

        // "Add" it to each of the documents.
        unsigned int index;
        for (index = 0; index < documentCount; index++) {
            [[I_documentsWithPendingDisplay objectAtIndex:index] addWindowController:windowController];
            [(PlainTextDocument *)[I_documentsWithPendingDisplay objectAtIndex:index] handleOpenDocumentEvent];

        }

        // Make the first document the current one.
        [windowController setDocument:[I_documentsWithPendingDisplay objectAtIndex:0]];

        // Show the window.
        [windowController showWindow:self];

        // Release the window controller. It will be deallocated when all of the documents have been closed.
        [windowController release];

    } // else something inexplicable has happened. Ignore it (instead of crashing).
    [I_documentsWithPendingDisplay removeAllObjects];
}

- (void)addProxyDocumentWithSession:(TCMMMSession *)aSession {
    PlainTextDocument *document = [[PlainTextDocument alloc] initWithSession:aSession];
    [document makeProxyWindowController];
    [self addDocument:document];
    [document showWindows];
    [document release];
}

- (NSArray *)documentsInMode:(DocumentMode *)aDocumentMode {
    NSMutableArray *result=[NSMutableArray array];
    NSEnumerator *documents=[[self documents] objectEnumerator];
    PlainTextDocument *document=nil;
    while ((document=[documents nextObject])) {
        if ([[document documentMode] isEqual:aDocumentMode]) {
            [result addObject:document];
        }
    }
    return result;
}

- (int)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions {
    if (![NSBundle loadNibNamed:@"OpenPanelAccessory" owner:self])  {
        NSLog(@"Failed to load OpenPanelAccessory.nib");
        return nil;
    }
        
    [O_modePopUpButton setHasAutomaticMode:YES];
    [O_modePopUpButton setSelectedModeIdentifier:AUTOMATICMODEIDENTIFIER];
    [O_encodingPopUpButton setEncoding:ModeStringEncoding defaultEntry:YES modeEntry:YES lossyEncodings:nil];
    [openPanel setAccessoryView:O_openPanelAccessoryView];
    [O_openPanelAccessoryView release];
    O_openPanelAccessoryView = nil;

    BOOL flag = [[NSUserDefaults standardUserDefaults] boolForKey:@"GoIntoBundlesPrefKey"];
    [openPanel setTreatsFilePackagesAsDirectories:flag];
    [openPanel setCanChooseDirectories:YES];
    [O_goIntoBundlesCheckbox setState:flag ? NSOnState : NSOffState];
    
    if ([openPanel canShowHiddenFiles]) {
        flag = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowsHiddenFiles"];
        [openPanel setInternalShowsHiddenFiles:flag];
        [O_showHiddenFilesCheckbox setState:flag ? NSOnState : NSOffState];
    } else {
        [O_showHiddenFilesCheckbox setHidden:YES];
    }
    
    I_openPanel = openPanel;
    int result = [super runModalOpenPanel:openPanel forTypes:extensions];
    I_openPanel = nil;
    
    [self setModeIdentifierFromLastRunOpenPanel:[O_modePopUpButton selectedModeIdentifier]];
    [self setEncodingFromLastRunOpenPanel:[[O_encodingPopUpButton selectedItem] tag]];
        
    return result;
}

- (NSArray *)fileNamesFromRunningOpenPanel {
    NSArray *fileNamesFromRunningOpenPanel = [super fileNamesFromRunningOpenPanel];
    NSMutableArray *fileNames = [NSMutableArray array];
    NSEnumerator *enumerator = [fileNamesFromRunningOpenPanel objectEnumerator];
    NSString *fileName;
    while ((fileName = [enumerator nextObject])) {
        BOOL isDir = NO;
        BOOL isFilePackage = [[NSWorkspace sharedWorkspace] isFilePackageAtPath:fileName];
        NSString *extension = [fileName pathExtension];
        if (isFilePackage && [extension isEqualToString:@"mode"]) {
            [self openModeFile:fileName];
        } else if ([[NSFileManager defaultManager] fileExistsAtPath:fileName isDirectory:&isDir] && isDir && !isFilePackage) {
            [self openDirectory:fileName];
        } else {
            [fileNames addObject:fileName];
        }
    }
    [I_fileNamesFromLastRunOpenPanel removeAllObjects];
    [I_fileNamesFromLastRunOpenPanel addObjectsFromArray:fileNames];
    return fileNames;
}

- (NSArray *)URLsFromRunningOpenPanel {
    NSArray *URLsFromRunningOpenPanel = [super URLsFromRunningOpenPanel];
    NSMutableArray *URLs = [NSMutableArray array];
    [I_fileNamesFromLastRunOpenPanel removeAllObjects];
    NSEnumerator *enumerator = [URLsFromRunningOpenPanel objectEnumerator];
    NSURL *URL;
    while ((URL = [enumerator nextObject])) {
        if ([URL isFileURL]) {
            NSString *fileName = [URL path];
            BOOL isDir = NO;
            BOOL isFilePackage = [[NSWorkspace sharedWorkspace] isFilePackageAtPath:fileName];
            NSString *extension = [fileName pathExtension];
            if (isFilePackage && [extension isEqualToString:@"mode"]) {
                [self openModeFile:fileName];
            } else if ([[NSFileManager defaultManager] fileExistsAtPath:fileName isDirectory:&isDir] && isDir && !isFilePackage) {
                [self openDirectory:fileName];
            } else {
                [I_fileNamesFromLastRunOpenPanel addObject:fileName];
                [URLs addObject:URL];
            }        
        }
    }
        
    return URLs;
}

- (NSStringEncoding)encodingFromLastRunOpenPanel {
    return I_encodingFromLastRunOpenPanel;
}

- (NSString *)modeIdentifierFromLastRunOpenPanel {
    return I_modeIdentifierFromLastRunOpenPanel;
}

- (BOOL)isDocumentFromLastRunOpenPanel:(NSDocument *)aDocument {
    int index = [I_fileNamesFromLastRunOpenPanel indexOfObject:[aDocument fileName]];
    if (index == NSNotFound) {
        return NO;
    }
    [I_fileNamesFromLastRunOpenPanel removeObjectAtIndex:index];
    return YES;
}

- (NSDictionary *)propertiesForOpenedFile:(NSString *)fileName {
    return [I_propertiesForOpenedFiles objectForKey:fileName];
}

- (BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"File operation error: %@ with file: %@", nil), [errorInfo objectForKey:@"Error"], [errorInfo objectForKey:@"Path"]]];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    (void)[alert runModal];
    return YES;
}



- (PlainTextWindowController *)activeWindowController {
    int count = [I_windowControllers count];
    if (count == 0) {
        PlainTextWindowController *controller = [[PlainTextWindowController alloc] init];
        [I_windowControllers addObject:controller];
        [controller release];
        count++;
    }
    PlainTextWindowController *wc = nil;
    while (--count >= 0) {
        wc = [I_windowControllers objectAtIndex:count];
        if ([[wc window] isMainWindow]) break;
    }
    return wc;
}

- (void)addWindowController:(id)aWindowController {
    [I_windowControllers addObject:aWindowController];
}

- (void)removeWindowController:(id)aWindowController {
    [I_windowControllers removeObject:[[aWindowController retain] autorelease]];
}




- (id)openDocumentWithContentsOfFile:(NSString *)fileName display:(BOOL)flag {
    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"openDocumentWithContentsOfFile:display");
    
    //NSDocument *document = [super openDocumentWithContentsOfFile:fileName display:flag];
    //if (document && flag) {
    //    [(PlainTextDocument *)document handleOpenDocumentEvent];
    //}
    
    id document;
    if ([self documentForFileName:fileName] || !flag) {
        document = [super openDocumentWithContentsOfFile:fileName display:flag];
    } else {
        // Open the document, but don't display it yet.
        document = [super openDocumentWithContentsOfFile:fileName display:NO];
        if (document) {
            // Schedule the display of the document with all of the others in a batch.
            if ([I_documentsWithPendingDisplay count] == 0) {
                [self performSelector:@selector(displayPendingDocuments) withObject:nil afterDelay:0.0f];
            }
            [I_documentsWithPendingDisplay addObject:document];
        }

    }
        
    return document;
}

- (id)openUntitledDocumentOfType:(NSString *)docType display:(BOOL)display {
    NSAppleEventDescriptor *eventDesc = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
    if ([eventDesc eventClass] == 'Hdra' && [eventDesc eventID] == 'See ') {
        I_isOpeningUntitledDocument = NO;
    } else {
        I_isOpeningUntitledDocument = YES;
    }
    NSDocument *document = [super openUntitledDocumentOfType:docType display:display];
    I_isOpeningUntitledDocument = NO;
    return document;
}

- (BOOL)isOpeningUntitledDocument {
    return I_isOpeningUntitledDocument;
}

- (void)removeDocument:(NSDocument *)document {
    int i;
    NSArray *keys = [I_waitingDocuments allKeys];
    int count = [keys count];
    for (i = count - 1; i >=0; i--) {
        NSString *key = [keys objectAtIndex:i];
        NSMutableArray *documents = [I_waitingDocuments objectForKey:key];
        if ([documents containsObject:document]) {
            BOOL isPiping = [I_pipingSeeScriptCommands containsObject:key];
            int refCount = [[I_refCountsOfSeeScriptCommands objectForKey:key] intValue];
            refCount--;
            if (refCount < 1) {
                NSMutableArray *fileNames = [NSMutableArray array];
                NSEnumerator *enumerator = [documents objectEnumerator];
                NSDocument *doc;
                while ((doc = [enumerator nextObject])) {
                    if (isPiping) {
                        NSString *fileName = tempFileName();
                        BOOL result = [doc writeToFile:fileName ofType:@"PlainTextType"];
                        if (result) {
                            [fileNames addObject:fileName];
                        }
                    }
                }
                NSScriptCommand *command = [I_suspendedSeeScriptCommands objectForKey:key];
                [command resumeExecutionWithResult:fileNames];
                [I_suspendedSeeScriptCommands removeObjectForKey:key];
                [I_waitingDocuments removeObjectForKey:key];
                [I_refCountsOfSeeScriptCommands removeObjectForKey:key];
                [I_pipingSeeScriptCommands removeObject:key];
            } else {
                [I_refCountsOfSeeScriptCommands setObject:[NSNumber numberWithInt:refCount] forKey:key];
            }
        }
    }
    
    [super removeDocument:document];
    if ([[self documents] count]==0) {
        NSMenu *modeMenu=[[[NSApp mainMenu] itemWithTag:ModeMenuTag] submenu];
        // remove all items that don't belong here anymore
        int index = [modeMenu indexOfItemWithTag:HighlightSyntaxMenuTag];
        index+=1; 
        while (index < [modeMenu numberOfItems]) {
            [modeMenu removeItemAtIndex:index];
        }
    }
}

- (id)handleOpenScriptCommand:(NSScriptCommand *)command {
    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"command: %@", [command description]);

    NSMutableDictionary *properties = [NSMutableDictionary dictionary];

    NSScriptClassDescription *classDescription = [[NSScriptSuiteRegistry sharedScriptSuiteRegistry] 
                                                    classDescriptionWithAppleEventCode:'docu'];
    
    NSDictionary *evaluatedProperties = [[command evaluatedArguments] objectForKey:@"WithProperties"];
    NSEnumerator *enumerator = [evaluatedProperties keyEnumerator];
    id argumentKey;
    while ((argumentKey = [enumerator nextObject])) {
        if ([argumentKey isKindOfClass:[NSNumber class]]) {
            NSString *key = [classDescription keyWithAppleEventCode:[argumentKey unsignedLongValue]];
            if (key) {
                if ([argumentKey unsignedLongValue] == 'Mode') {
                    // Workaround for see tool and older scripts which assume that the mode property is a string.
                    // Properties aren't coerced automatically.
                    [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:@"mode"];
                } else {
                    [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:key];
                }
            }
        } else if ([argumentKey isKindOfClass:[NSString class]]) {
            [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:argumentKey];
        }
    }
    
    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"properties: %@", properties);
    
    NSMutableArray *files = [NSMutableArray array];
    id directParameter = [command directParameter];
    if ([directParameter isKindOfClass:[NSArray class]]) {
        id file;
        NSEnumerator *parameterEnumerator = [directParameter objectEnumerator];
        while ((file = [parameterEnumerator nextObject])) {
            if ([file isKindOfClass:[NSURL class]]) {
                [files addObject:[file path]];
            } else {
                [files addObject:file];
            }
        }
    } else if ([directParameter isKindOfClass:[NSString class]]) {
        [files addObject:directParameter];
    } else if ([directParameter isKindOfClass:[NSURL class]]) {
        [files addObject:[directParameter path]];
    }
    
    enumerator = [files objectEnumerator];
    NSString *filename;
    while ((filename = [enumerator nextObject])) {
        BOOL isDir = NO;
        BOOL isFilePackage = [[NSWorkspace sharedWorkspace] isFilePackageAtPath:filename];
        NSString *extension = [filename pathExtension];
        if (isFilePackage && [extension isEqualToString:@"mode"]) {
            [self openModeFile:filename];
        } else if ([[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&isDir] && isDir && !isFilePackage) {
            [self openDirectory:filename];
        } else if ([[filename pathExtension] isEqualToString:@"seestyle"]) {
            TCMPreferenceController *prefController = [TCMPreferenceController sharedInstance];
            [prefController showWindow:self];
            BOOL result = [prefController selectPreferenceModuleWithIdentifier:@"de.codingmonkeys.subethaedit.preferences.style"];
            if (result) {
                TCMPreferenceModule *prefModule = [prefController preferenceModuleWithIdentifier:@"de.codingmonkeys.subethaedit.preferences.style"];
                if (prefModule) {
                    [(StylePreferences *)prefModule importStyleFile:filename];
                }
            }
        } else {
            [I_propertiesForOpenedFiles setObject:properties forKey:filename];
            (void)[self openDocumentWithContentsOfFile:filename display:YES];
        }
    }
            
    return nil;
}

- (id)handlePrintScriptCommand:(NSScriptCommand *)command {
    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"command: %@", [command description]);

    NSMutableDictionary *properties = [NSMutableDictionary dictionary];

    NSScriptClassDescription *classDescription = [[NSScriptSuiteRegistry sharedScriptSuiteRegistry] 
                                                    classDescriptionWithAppleEventCode:'docu'];
    
    NSDictionary *evaluatedProperties = [[command evaluatedArguments] objectForKey:@"WithProperties"];
    NSEnumerator *enumerator = [evaluatedProperties keyEnumerator];
    id argumentKey;
    while ((argumentKey = [enumerator nextObject])) {
        if ([argumentKey isKindOfClass:[NSNumber class]]) {
            NSString *key = [classDescription keyWithAppleEventCode:[argumentKey unsignedLongValue]];
            if (key) {
                if ([argumentKey unsignedLongValue] == 'Mode') {
                    // Workaround for see tool and older scripts which assume that the mode property is a string.
                    // Properties aren't coerced automatically.
                    [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:@"mode"];
                } else {
                    [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:key];
                }
            }
        } else if ([argumentKey isKindOfClass:[NSString class]]) {
            [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:argumentKey];
        }
    }
    
    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"properties: %@", properties);
    
    NSMutableArray *files = [NSMutableArray array];
    id directParameter = [command directParameter];
    if ([directParameter isKindOfClass:[NSArray class]]) {
        id file;
        NSEnumerator *parameterEnumerator = [directParameter objectEnumerator];
        while ((file = [parameterEnumerator nextObject])) {
            if ([file isKindOfClass:[NSURL class]]) {
                [files addObject:[file path]];
            } else {
                [files addObject:file];
            }
        }
    } else if ([directParameter isKindOfClass:[NSString class]]) {
        [files addObject:directParameter];
    } else if ([directParameter isKindOfClass:[NSURL class]]) {
        [files addObject:[directParameter path]];
    }
    
    enumerator = [files objectEnumerator];
    NSString *filename;
    while ((filename = [enumerator nextObject])) {
        [I_propertiesForOpenedFiles setObject:properties forKey:filename];
        BOOL shouldClose = ([self documentForFileName:filename] == nil);
        PlainTextDocument *document = [self openDocumentWithContentsOfFile:filename display:YES];
        [document printShowingPrintPanel:NO];
        if (shouldClose) {
            [document close];
        }
    }

    return nil;
}

- (id)handleSeeScriptCommand:(NSScriptCommand *)command {
    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"command: %@", [command description]);

    NSScriptClassDescription *classDescription = [[NSScriptSuiteRegistry sharedScriptSuiteRegistry] 
                                                    classDescriptionWithAppleEventCode:'docu'];
    
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    NSDictionary *evaluatedProperties = [[command evaluatedArguments] objectForKey:@"WithProperties"];
    NSEnumerator *enumerator = [evaluatedProperties keyEnumerator];
    id argumentKey;
    while ((argumentKey = [enumerator nextObject])) {
        if ([argumentKey isKindOfClass:[NSNumber class]]) {
            NSString *key = [classDescription keyWithAppleEventCode:[argumentKey unsignedLongValue]];
            if (key) {
                if ([argumentKey unsignedLongValue] == 'Mode') {
                    // Workaround for see tool and older scripts which assume that the mode property is a string.
                    // Properties aren't coerced automatically.
                    [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:@"mode"];
                } else {
                    [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:key];
                }
            }
        } else if ([argumentKey isKindOfClass:[NSString class]]) {
            [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:argumentKey];
        }
    }
    
    
    NSString *jobDescription = [[command evaluatedArguments] objectForKey:@"JobDescription"];    
    BOOL shouldPrint = [[[command evaluatedArguments] objectForKey:@"ShouldPrint"] boolValue];
    BOOL isPipingOut = [[[command evaluatedArguments] objectForKey:@"PipeOut"] boolValue];
    BOOL shouldWait = [[[command evaluatedArguments] objectForKey:@"ShouldWait"] boolValue];
    
    NSMutableArray *documents = [NSMutableArray array];
    
    NSMutableArray *files = [NSMutableArray array];
    id argument = [[command evaluatedArguments] objectForKey:@"Files"];
    if ([argument isKindOfClass:[NSArray class]]) {
        [files addObjectsFromArray:argument];
    } else if ([argument isKindOfClass:[NSString class]]) {
        [files addObject:argument];
    } else if ([argument isKindOfClass:[NSURL class]]) {
        [files addObject:[argument path]];
    }

    enumerator = [files objectEnumerator];
    NSString *fileName;
    while ((fileName = [enumerator nextObject])) {
        [I_propertiesForOpenedFiles setObject:properties forKey:fileName];
        NSDocument *document = [self openDocumentWithContentsOfFile:fileName display:YES];
        if (document) {
            [(PlainTextDocument *)document setIsWaiting:(shouldWait || isPipingOut)];
            if (jobDescription) {
                [(PlainTextDocument *)document setJobDescription:jobDescription];
            }
            if (shouldPrint) {
                [document printShowingPrintPanel:NO];
                [document close];            
            } else {
                [documents addObject:document];
            }
        }
    }

    
    NSMutableArray *newFiles = [NSMutableArray array];
    argument = [[command evaluatedArguments] objectForKey:@"NewFiles"];
    if ([argument isKindOfClass:[NSArray class]]) {
        [newFiles addObjectsFromArray:argument];
    } else if ([argument isKindOfClass:[NSString class]]) {
        [newFiles addObject:argument];
    } else if ([argument isKindOfClass:[NSURL class]]) {
        [newFiles addObject:[argument path]];
    }
    
    NSString *documentModeIdentifierArgument = [properties objectForKey:@"mode"];
    enumerator = [newFiles objectEnumerator];
    while ((fileName = [enumerator nextObject])) {
        NSDocument *document = [self openUntitledDocumentOfType:@"PlainTextType" display:YES];
        if (document) {
            [(PlainTextDocument *)document setIsWaiting:(shouldWait || isPipingOut)];
            if (!documentModeIdentifierArgument) {
                DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForExtension:[fileName pathExtension]];
                [properties setObject:[mode documentModeIdentifier] forKey:@"mode"];
            }
            if ([properties objectForKey:@"encoding"] == nil && documentModeIdentifierArgument != nil) {
                DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForName:documentModeIdentifierArgument];
                if (mode) {
                    unsigned int encodingNumber = [[mode defaultForKey:DocumentModeEncodingPreferenceKey] unsignedIntValue];
                    if (encodingNumber < SmallestCustomStringEncoding) {
                        NSString *IANAName = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(encodingNumber));
                        if (IANAName != nil) {
                            [properties setObject:IANAName forKey:@"encoding"];
                        }
                    }
                } else {
                    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"mode name argument invalid: %@", documentModeIdentifierArgument);
                }
            }            
            [document setScriptingProperties:properties];
            [(PlainTextDocument *)document resizeAccordingToDocumentMode];
            [(PlainTextDocument *)document setShouldSelectModeOnSave:NO];
            [(PlainTextDocument *)document setShouldChangeExtensionOnModeChange:NO];
            [(PlainTextDocument *)document setTemporaryDisplayName:[fileName lastPathComponent]];
            [(PlainTextDocument *)document setDirectoryForSavePanel:[fileName stringByDeletingLastPathComponent]];
            if (jobDescription) {
                [(PlainTextDocument *)document setJobDescription:jobDescription];
            }
            if (shouldPrint) {
                [document printShowingPrintPanel:NO];
                [document close];
            } else {
                [documents addObject:document];
            }
        }
    }
        
    
    NSString *standardInputFile = nil;
    argument = [[command evaluatedArguments] objectForKey:@"Stdin"];
    if ([argument isKindOfClass:[NSString class]]) {
        standardInputFile = argument;
    } else if ([argument isKindOfClass:[NSURL class]]) {
        standardInputFile = [argument path];
    }
    
    if (standardInputFile) {
        NSString *pipeTitle = [[command evaluatedArguments] objectForKey:@"PipeTitle"];
    
        NSDocument *document = [self openUntitledDocumentOfType:@"PlainTextType" display:YES];
        if (document) {
            [(PlainTextDocument *)document setIsWaiting:(shouldWait || isPipingOut)];
            if (isPipingOut) {
                [(PlainTextDocument *)document setShouldChangeChangeCount:NO];
            }
            if (pipeTitle) {
                [(PlainTextDocument *)document setTemporaryDisplayName:pipeTitle];
            } 
            
            [document setScriptingProperties:properties];
            [I_propertiesForOpenedFiles setObject:properties forKey:standardInputFile];
            [(PlainTextDocument *)document resizeAccordingToDocumentMode];
            [document readFromFile:standardInputFile ofType:@"PlainTextType"];
            if (!pipeTitle) {
                [(PlainTextDocument *)document setShouldChangeExtensionOnModeChange:YES];
            }

            if (pipeTitle && ![properties objectForKey:@"mode"]) {
                DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForExtension:[pipeTitle pathExtension]];
                [(PlainTextDocument *)document setDocumentMode:mode];
                [(PlainTextDocument *)document resizeAccordingToDocumentMode];
                [(PlainTextDocument *)document setShouldSelectModeOnSave:NO];
            } else if (![properties objectForKey:@"mode"]) {
                [(PlainTextDocument *)document setShouldSelectModeOnSave:YES];
            }
            
            if (jobDescription) {
                [(PlainTextDocument *)document setJobDescription:jobDescription];
            }
            
            if (shouldPrint) {
                [document printShowingPrintPanel:NO];
                [document close];            
            } else {
                [documents addObject:document];
            }
        }
    }
    
    NSString *identifier = [NSString UUIDString];

    if (isPipingOut) {
        [I_pipingSeeScriptCommands addObject:identifier];
    }
    
    if (shouldWait) {
        int count = [documents count];
        if (count > 0) {
            [command suspendExecution];
            [I_suspendedSeeScriptCommands setObject:command forKey:identifier];
            [I_waitingDocuments setObject:documents forKey:identifier];
            [I_refCountsOfSeeScriptCommands setObject:[NSNumber numberWithInt:count] forKey:identifier];
        }
    }
    
    return nil;
}

- (void)newDocumentWithModeMenuItem:(id)aSender {
    DocumentModeManager *modeManager=[DocumentModeManager sharedInstance];
    NSString *identifier=[modeManager documentModeIdentifierForTag:[aSender tag]];
    if (identifier) {
        PlainTextDocument *document = (PlainTextDocument *)[self openUntitledDocumentOfType:@"PlainTextType" display:NO];
        DocumentMode *newMode=[modeManager documentModeForIdentifier:identifier];
        [document setDocumentMode:newMode];
        [document showWindows];
        #warning: Issue with multi-document windows
        [document resizeAccordingToDocumentMode];
        NSStringEncoding encoding = [[newMode defaultForKey:DocumentModeEncodingPreferenceKey] unsignedIntValue];
        if (encoding < SmallestCustomStringEncoding) {
            [document setFileEncoding:encoding];
        }
        NSString *newFileContent=[newMode newFileContent];
        if (newFileContent && ![newFileContent canBeConvertedToEncoding:[document fileEncoding]]) {
            newFileContent=[[[NSString alloc] 
                            initWithData:[newFileContent dataUsingEncoding:[document fileEncoding] allowLossyConversion:YES] 
                            encoding:[document fileEncoding]] 
                              autorelease];
        }
        if (newFileContent) {
            TextStorage *textStorage=(TextStorage *)[document textStorage];
            [textStorage replaceCharactersInRange:NSMakeRange(0,[textStorage length]) withString:newFileContent];
            [document updateChangeCount:NSChangeCleared];
        }
    }
}



#pragma mark -

#pragma options align=mac68k
struct ModificationInfo
{
    FSSpec theFile; // identifies the file
    long theDate; // the date/time the file was last modified
    short saved; // set this to zero when replying
};
#pragma options align=reset

- (void)handleAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"handleAppleEvent: %@, withReplyEvent: %@", [event description], [replyEvent description]);
    OSErr err;
    
    if ([event eventClass] == kKAHL && [event eventID] == kMOD) {
        NSAppleEventDescriptor *listDesc = [NSAppleEventDescriptor listDescriptor];
        NSArray *documents = [self documents];
        NSEnumerator *enumerator = [documents objectEnumerator];
        NSDocument *document;
        while ((document = [enumerator nextObject])) {
            if ([document isDocumentEdited]) {
                NSString *name = [document fileName];
                if (name != nil) {
                    NSURL *fileURL = [NSURL fileURLWithPath:name];
                    FSRef fileRef;
                    CFURLGetFSRef((CFURLRef)fileURL, &fileRef);
                    FSSpec fsSpec;
                    err = FSGetCatalogInfo(&fileRef, kFSCatInfoNone, NULL, NULL, &fsSpec, NULL);
                    if (err == noErr) {
                        struct ModificationInfo modificationInfo;
                        modificationInfo.theFile = fsSpec;
                        modificationInfo.theDate = 0;
                        modificationInfo.saved = 0;
                        NSAppleEventDescriptor *modificationInfoDesc = [NSAppleEventDescriptor descriptorWithDescriptorType:typeChar bytes:&modificationInfo length:sizeof(struct ModificationInfo)];
                        [listDesc insertDescriptor:modificationInfoDesc atIndex:0];
                    }
                }
            }
        }
        [replyEvent setDescriptor:listDesc forKeyword:keyDirectObject];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL selector = [menuItem action];
    
    if (selector == @selector(concealAllDocuments:)) {
        return [[[TCMMMPresenceManager sharedInstance] announcedSessions] count]>0;
    } 
    return [super validateMenuItem:menuItem];
}

#pragma mark -

- (IBAction)goIntoBundles:(id)sender {
    BOOL flag = ([sender state] == NSOffState) ? NO : YES;
    [I_openPanel setTreatsFilePackagesAsDirectories:flag];
    [[NSUserDefaults standardUserDefaults] setBool:flag forKey:@"GoIntoBundlesPrefKey"];
}

- (IBAction)showHiddenFiles:(id)sender {
    BOOL flag = ([sender state] == NSOffState) ? NO : YES;
    if ([I_openPanel canShowHiddenFiles]) {
        [I_openPanel setInternalShowsHiddenFiles:flag];
    }
    [[NSUserDefaults standardUserDefaults] setBool:flag forKey:@"ShowsHiddenFiles"];
}

- (IBAction)installMode:(id)sender {
    [NSApp stopModal];
}

- (IBAction)changeModeInstallationDomain:(id)sender {
    int tag = [[O_modeInstallerDomainMatrix selectedCell] tag];
    NSString *informativeText = @"";
    NSBundle *modeBundle = [NSBundle bundleWithPath:I_currentModeFileName];
    NSString *modeIdentifier = [modeBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForIdentifier:modeIdentifier];
    if (mode) {
        NSBundle *installedModeBundle = [mode bundle];
        NSString *versionStringOfInstalledMode = [installedModeBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSString *installedModeFileName = [installedModeBundle bundlePath];
        NSString *installedModeName = [NSString stringWithFormat:@"%@ (%@)", [installedModeFileName lastPathComponent], versionStringOfInstalledMode];
        informativeText = [NSString stringWithFormat:NSLocalizedString(@"Mode \"%@\" is already installed in \"%@\".", nil), installedModeName, installedModeFileName];
        
        short domain;
        BOOL isKnownDomain = YES;
        if ([installedModeFileName hasPrefix:@"/Users/"]) {
            domain = kUserDomain;
        } else if ([installedModeFileName hasPrefix:@"/Library/"]) {
            domain = kLocalDomain;
        } else if ([installedModeFileName hasPrefix:@"/Network/"]) {
            domain = kNetworkDomain;
        } else {
            isKnownDomain = NO;
        }

        if (tag == 0) {
            if (!isKnownDomain || domain == kNetworkDomain || domain == kLocalDomain) {
                informativeText = [informativeText stringByAppendingFormat:@" %@", NSLocalizedString(@"You will override the installed mode.", nil)];
            } else if (domain == kUserDomain) {
                informativeText = [informativeText stringByAppendingFormat:@" %@", NSLocalizedString(@"You will replace the installed mode.", nil)];
            }
        } else if (tag == 1) {
            if (!isKnownDomain || domain == kNetworkDomain) {
                informativeText = [informativeText stringByAppendingFormat:@" %@", NSLocalizedString(@"You will override the installed mode.", nil)];
            } else if (domain == kLocalDomain) {
                informativeText = [informativeText stringByAppendingFormat:@" %@", NSLocalizedString(@"You will replace the installed mode.", nil)];
            } else if (domain == kUserDomain) {
                informativeText = [informativeText stringByAppendingFormat:@" %@", NSLocalizedString(@"The installed mode will override your new mode.", nil)];
            }
        }
    }
    
    if (tag == 1) { 
        if ([informativeText length] > 0)
            informativeText = [informativeText stringByAppendingString:@" "];
        informativeText = [informativeText stringByAppendingString:NSLocalizedString(@"When you click Install, you'll be asked to enter the name and password for an administrator of this computer.", nil)];
    }
    [O_modeInstallerInformativeTextField setObjectValue:informativeText];
}

- (IBAction)cancelModeInstallation:(id)sender {
    [NSApp abortModal];
}

- (IBAction)concealAllDocuments:(id)aSender {
    PlainTextDocument *document=nil;
    NSEnumerator *documents = [[self documents] objectEnumerator];
    while ((document=[documents nextObject])) {
        if ([document isAnnounced]) {
            [document setIsAnnounced:NO];
        }
    }
}

- (IBAction)closeAllDocuments:(id)sender {
    [self closeAllDocumentsWithDelegate:nil didCloseAllSelector:NULL contextInfo:NULL];
}

#pragma mark -

// note the "setServicesProvider:" in the applicationWillFinishLaunching method

- (void)openSelection:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error {
    PlainTextDocument *document = (PlainTextDocument *)[self openUntitledDocumentOfType:@"PlainTextType" display:YES];
    [[[[document plainTextEditors] objectAtIndex:0] textView] readSelectionFromPasteboard:pboard];
    // Workaround for when only RTF is on the drag pasteboard (e.g. when dragging text from safari on the SubEthaEditApplicationIcon)
    NSTextStorage *ts = [document textStorage];
    [ts removeAttribute:NSBackgroundColorAttributeName range:NSMakeRange(0,[ts length])];
    [ts removeAttribute:NSLinkAttributeName range:NSMakeRange(0,[ts length])];
    [document clearChangeMarks:self];
}

@end
