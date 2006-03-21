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


@interface DocumentController (DocumentControllerPrivateAdditions)

- (void)setModeIdentifierFromLastRunOpenPanel:(NSString *)modeIdentifier;
- (void)setEncodingFromLastRunOpenPanel:(NSStringEncoding)stringEncoding;

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
    [super dealloc];
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
    NSArray *fileNames = [super fileNamesFromRunningOpenPanel];
    [I_fileNamesFromLastRunOpenPanel removeAllObjects];
    [I_fileNamesFromLastRunOpenPanel addObjectsFromArray:fileNames];
    return fileNames;
}

- (NSArray *)URLsFromRunningOpenPanel {
    NSArray *URLs = [super URLsFromRunningOpenPanel];
    
    [I_fileNamesFromLastRunOpenPanel removeAllObjects];
    NSEnumerator *enumerator = [URLs objectEnumerator];
    NSURL *URL;
    while ((URL = [enumerator nextObject])) {
        if ([URL isFileURL]) {
            [I_fileNamesFromLastRunOpenPanel addObject:[URL path]];
        }
    }
    
    return URLs;
}

- (void)setEncodingFromLastRunOpenPanel:(NSStringEncoding)stringEncoding {
    I_encodingFromLastRunOpenPanel = stringEncoding;
}

- (NSStringEncoding)encodingFromLastRunOpenPanel {
    return I_encodingFromLastRunOpenPanel;
}

- (void)setModeIdentifierFromLastRunOpenPanel:(NSString *)modeIdentifier {
    [I_modeIdentifierFromLastRunOpenPanel release];
    I_modeIdentifierFromLastRunOpenPanel = [modeIdentifier copy];
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

- (id)openDocumentWithContentsOfFile:(NSString *)fileName display:(BOOL)flag {
    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"openDocumentWithContentsOfFile:display");
    
    BOOL isFilePackage = [[NSWorkspace sharedWorkspace] isFilePackageAtPath:fileName];
    NSString *extension = [fileName pathExtension];
    if (isFilePackage && [extension isEqualToString:@"mode"]) {
        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"User tries to open a mode file");
        int result = [NSApp runModalForWindow:O_modeInstallerPanel];
        [O_modeInstallerPanel orderOut:self];
        if (result == NSRunStoppedResponse) {
            int tag = [[O_modeInstallerDomainMatrix selectedCell] tag];
            if (tag == 0) {
                // User
            } else if (tag == 1) {
                // Computer
            } else if (tag == 2) {
                // Network
            }
        }
        return nil;
    }
    
    NSDocument *document = [super openDocumentWithContentsOfFile:fileName display:flag];
    if (document && flag) {
        [(PlainTextDocument *)document handleOpenDocumentEvent];
    }
    return document;
}

- (IBAction)installMode:(id)sender {
    [NSApp stopModal];
}

- (IBAction)cancelModeInstallation:(id)sender {
    [NSApp abortModal];
}

- (id)openUntitledDocumentOfType:(NSString *)docType display:(BOOL)display {
    I_isOpeningUntitledDocument = YES;
    NSDocument *document = [super openUntitledDocumentOfType:docType display:display];
    I_isOpeningUntitledDocument = NO;
    return document;
}

- (BOOL)isOpeningUntitledDocument {
    return I_isOpeningUntitledDocument;
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
}

- (id)handleOpenScriptCommand:(NSScriptCommand *)command {
    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"command: %@", [command description]);

    NSMutableDictionary *properties = [NSMutableDictionary dictionary];

    NSScriptClassDescription *classDescription = [[NSScriptSuiteRegistry sharedScriptSuiteRegistry] 
                                                    classDescriptionWithAppleEventCode:'pltd'];
    
    NSDictionary *evaluatedProperties = [[command evaluatedArguments] objectForKey:@"WithProperties"];
    NSEnumerator *enumerator = [evaluatedProperties keyEnumerator];
    id argumentKey;
    while ((argumentKey = [enumerator nextObject])) {
        if ([argumentKey isKindOfClass:[NSNumber class]]) {
            NSString *key = [classDescription keyWithAppleEventCode:[argumentKey unsignedLongValue]];
            if (key) {
                [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:key];
            }
        } else if ([argumentKey isKindOfClass:[NSString class]]) {
            [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:argumentKey];
        }
    }
    
    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"properties: %@", properties);
    
    NSMutableArray *files = [NSMutableArray array];
    id directParameter = [command directParameter];
    if ([directParameter isKindOfClass:[NSArray class]]) {
        [files addObjectsFromArray:directParameter];
    } else if ([directParameter isKindOfClass:[NSString class]]) {
        [files addObject:directParameter];
    } else if ([directParameter isKindOfClass:[NSURL class]]) {
        [files addObject:[directParameter path]];
    }
    
    enumerator = [files objectEnumerator];
    NSString *filename;
    while ((filename = [enumerator nextObject])) {
        if ([[filename pathExtension] isEqualToString:@"seestyle"]) {
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
                                                    classDescriptionWithAppleEventCode:'pltd'];
    
    NSDictionary *evaluatedProperties = [[command evaluatedArguments] objectForKey:@"WithProperties"];
    NSEnumerator *enumerator = [evaluatedProperties keyEnumerator];
    id argumentKey;
    while ((argumentKey = [enumerator nextObject])) {
        if ([argumentKey isKindOfClass:[NSNumber class]]) {
            NSString *key = [classDescription keyWithAppleEventCode:[argumentKey unsignedLongValue]];
            if (key) {
                [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:key];
            }
        } else if ([argumentKey isKindOfClass:[NSString class]]) {
            [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:argumentKey];
        }
    }
    
    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"properties: %@", properties);
    
    NSMutableArray *files = [NSMutableArray array];
    id directParameter = [command directParameter];
    if ([directParameter isKindOfClass:[NSArray class]]) {
        [files addObjectsFromArray:directParameter];
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
                                                    classDescriptionWithAppleEventCode:'pltd'];
    
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    NSDictionary *evaluatedProperties = [[command evaluatedArguments] objectForKey:@"WithProperties"];
    NSEnumerator *enumerator = [evaluatedProperties keyEnumerator];
    id argumentKey;
    while ((argumentKey = [enumerator nextObject])) {
        if ([argumentKey isKindOfClass:[NSNumber class]]) {
            NSString *key = [classDescription keyWithAppleEventCode:[argumentKey unsignedLongValue]];
            if (key) {
                [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:key];
            } else 
                // Workaround for see tool which assumes that the mode property is still 'Mode'.
                if ([argumentKey unsignedLongValue] == 'Mode') {
                    [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:@"mode"];
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
        PlainTextDocument *document = (PlainTextDocument *)[self openUntitledDocumentOfType:@"PlainTextType" display:YES];
        DocumentMode *newMode=[modeManager documentModeForIdentifier:identifier];
        [document setDocumentMode:newMode];
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
#pragma mark ### NServices ###

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

@end
