//
//  DocumentController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Mar 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "DocumentController.h"
#import "TCMMMSession.h"
#import "PlainTextDocument.h"
#import "EncodingManager.h"
#import "DocumentModeManager.h"
#import "AppController.h"


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
        I_fileNamesFromLastRunOpenPanel = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc {
    [I_modeIdentifierFromLastRunOpenPanel release];
    [I_fileNamesFromLastRunOpenPanel release];
}

- (void)addDocumentWithSession:(TCMMMSession *)aSession {
    PlainTextDocument *document = [[PlainTextDocument alloc] initWithSession:aSession];
    [document makeWindowControllers];
    [self addDocument:document];
    [document showWindows];
    [document release];
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
    
    int result = [super runModalOpenPanel:openPanel forTypes:extensions];
    
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

@end
