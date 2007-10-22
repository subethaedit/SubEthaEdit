//
//  ServerConnectionWindowController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 26.04.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "ServerConnectionWindowController.h"
#import "ServerConnectionManager.h"
#import "FileManagementProfile.h"
#import "NSWorkspaceTCMAdditions.h"
#import "TCMMMSession.h"


@implementation ServerConnectionWindowController

- (id)initWithMMUser:(TCMMMUser *)aUser {
    if ((self=[super init])) {
        _user = [aUser retain];
        _BEEPSession = [[[TCMMMBEEPSessionManager sharedInstance] sessionForUserID:[aUser userID]] retain];
        [_BEEPSession startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/SeedFileManagement"] andData:nil sender:self];
    }
    return self;
}

- (void)dealloc {
    [_user release];
    [_BEEPSession release];
    [_profile setDelegate:nil];
    [_profile close];
    [_profile release];
    [super dealloc];
}

- (NSString *)serverAddress {
    return [NSString stringWithAddressData:[_BEEPSession peerAddressData]];
}

- (NSString *)windowNibName {
    return @"ServerConnection";
}

- (void)windowDidLoad {
    [O_encodingPopUpButton setEncoding:NSUTF8StringEncoding defaultEntry:NO modeEntry:NO lossyEncodings:nil];
    NSPopUpButtonCell *popUpButtonCell = [[O_tableView tableColumnWithIdentifier:@"AccessState"] dataCell];
    [popUpButtonCell addItemWithTitle:@"Locked"];
    [popUpButtonCell addItemWithTitle:@"Read Only"];
    [popUpButtonCell addItemWithTitle:@"Read/Write"];
    [[popUpButtonCell itemAtIndex:0] setTag:TCMMMSessionAccessLockedState];
    [[popUpButtonCell itemAtIndex:1] setTag:TCMMMSessionAccessReadOnlyState];
    [[popUpButtonCell itemAtIndex:2] setTag:TCMMMSessionAccessReadWriteState];
}

#pragma mark -

- (void)windowWillClose:(NSNotification *)aNotification {
    [[self retain] autorelease];
    [[ServerConnectionManager sharedInstance] removeWindowController:self];
}

- (void)realChangeAccessState {
    NSDictionary *dict = [[O_remoteFilesController selectedObjects] lastObject];
    NSDictionary *newDict = [NSDictionary dictionaryWithObject:[dict objectForKey:@"AccessState"] forKey:@"AccessState"];
    [_profile changeAttributes:newDict forFileWithID:[dict objectForKey:@"FileID"]];
}

- (IBAction)changeAccessState:(id)aSender {
    [self performSelector:@selector(realChangeAccessState) withObject:nil afterDelay:0];
}

- (void)realChangeAnnounced {
    NSDictionary *dict = [[O_remoteFilesController selectedObjects] lastObject];
    NSDictionary *newDict = [NSDictionary dictionaryWithObject:[dict objectForKey:@"IsAnnounced"] forKey:@"IsAnnounced"];
    [_profile changeAttributes:newDict forFileWithID:[dict objectForKey:@"FileID"]];
}

- (IBAction)changeAnnounced:(id)aSender {
    [self performSelector:@selector(realChangeAnnounced) withObject:nil afterDelay:0];
}


#pragma mark -
#pragma mark ### Profile Interaction ###

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didOpenChannelWithProfile:(TCMBEEPProfile *)aProfile data:(NSData *)inData {
    _profile = (FileManagementProfile *)aProfile;
    [[_profile retain] setDelegate:self];
    [_profile askForFileList];
}

- (void)addFileDict:(NSDictionary *)aFileDict {
    NSMutableDictionary *fileDictionary = [[aFileDict mutableCopy] autorelease];
    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFileType:[[fileDictionary objectForKey:@"FilePath"] pathExtension] size:16];
    if (icon) {
        [fileDictionary setObject:icon forKey:@"FileIcon"];
    }
    [O_remoteFilesController addObject:fileDictionary];
}

- (void)updateFileDict:(NSDictionary *)aFileDict {
    NSString *fileID = [aFileDict objectForKey:@"FileID"];
    NSMutableDictionary *fileDict = [[[O_remoteFilesController arrangedObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"FileID = %@",fileID]] lastObject];
    if (fileDict) {
        if ([[fileDict objectForKey:@"ChangeCount"] intValue] < [[aFileDict objectForKey:@"ChangeCount"] intValue]) {
            NSLog(@"--- :) %s USED update:%@",__FUNCTION__,aFileDict);
            [fileDict addEntriesFromDictionary:aFileDict];
        } else {
            NSLog(@"--- :( %s unused update:%@",__FUNCTION__,aFileDict);
        }
    } else {
        [self addFileDict:aFileDict];
    }
}

- (void)profile:(FileManagementProfile *)aProfile didReceiveFileList:(NSArray *)aContentArray {
    
    NSEnumerator *fileDicts = [aContentArray objectEnumerator];
    NSDictionary *fileDict = nil;
    while ((fileDict = [fileDicts nextObject])) {
        [self addFileDict:fileDict];
    }
}

- (IBAction)newFile:(id)aSender {
    [_profile requestNewFileWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
        [O_newfileNameTextField stringValue],@"FilePath",
        [O_modePopUpButton selectedModeIdentifier],@"ModeIdentifier",
        CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding([[O_encodingPopUpButton selectedItem] tag])),@"Encoding",
        [NSNumber numberWithInt:[[O_accessStatePopUpButton selectedItem] tag]],@"AccessState",
        nil]
    ];
}

- (void)profile:(FileManagementProfile *)aProfile didAckNewDocument:(NSDictionary *)aDocumentDictionary {
    [self updateFileDict:aDocumentDictionary];
}

- (void)profileDidClose:(TCMBEEPProfile *)aProfile {
    NSLog(@"%s %@",__FUNCTION__,aProfile);
}

- (void)profile:(TCMBEEPProfile *)aProfile didFailWithError:(NSError *)anError {
    NSLog(@"%s %@ %@",__FUNCTION__,aProfile,anError);
}

- (void)profile:(FileManagementProfile *)aProfile didReceiveFileUpdates:(NSDictionary *)aFileUpdateDictionary {
    NSEnumerator *fileIDs = [aFileUpdateDictionary keyEnumerator];
    NSString *fileID=nil;
    while ((fileID=[fileIDs nextObject])) {
        id object = [aFileUpdateDictionary objectForKey:fileID];
        if ([object isKindOfClass:[NSDictionary class]]) {
            [self updateFileDict:object];
        } else {
            // TODO: implement removal of documents
        }
    }
}

- (void)profile:(FileManagementProfile *)aProfile didAcceptSetResponse:(NSDictionary *)aDocumentDictionary wasFailure:(BOOL)aFailure {
    [self updateFileDict:aDocumentDictionary];
}


@end
