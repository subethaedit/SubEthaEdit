//
//  SDDocument.m
//  SubEthaEdit
//
//  Created by Martin Ott on 3/23/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "SDDocument.h"
#import "../TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "../SelectionOperation.h"
#import "../TextOperation.h"


NSString * const WrittenByUserIDAttributeName = @"WrittenByUserID";
NSString * const ChangedByUserIDAttributeName = @"ChangedByUserID";


@implementation SDDocument
 
- (void)_generateNewSession
{
    TCMMMSession *oldSession = [self session];
    if (oldSession) {
        [oldSession setDocument:nil];
        [[TCMMMPresenceManager sharedInstance] unregisterSession:[self session]];
    }
    TCMMMSession *newSession = [[TCMMMSession alloc] initWithDocument:self];
    if (oldSession) {
        NSString *name = [oldSession filename];
        [newSession setFilename:name];
        //[self setTemporaryDisplayName:[[self temporaryDisplayName] lastPathComponent]];
    }
    NSArray *contributors = [oldSession contributors];
    if ([contributors count]) {
        [newSession addContributors:contributors];
    }
    [self setSession:newSession];
    [newSession release];
    //[self setShouldChangeChangeCount:YES];
    [[TCMMMPresenceManager sharedInstance] registerSession:[self session]];
}

#pragma mark -

- (id)initWithContentsOfURL:(NSURL *)absoluteURL encoding:(NSStringEncoding)anEncoding error:(NSError **)outError {
    if ([self init]) {
        [self setStringEncoding:anEncoding];
        [self setFileURL:absoluteURL];
        if ([self readFromURL:absoluteURL error:outError]) {
            return self;
        } else {
            return nil;
        }
    } else {
        // create NSError
        return nil;
    }
}


- (id)initWithContentsOfURL:(NSURL *)absoluteURL error:(NSError **)outError
{
    return [self initWithContentsOfURL:absoluteURL encoding:NSUTF8StringEncoding error:outError];
}

- (id)init
{
    self = [super init];
    if (self) {
        _stringEncoding = NSUTF8StringEncoding;
        _attributedString = [[NSMutableAttributedString alloc] init];
        _flags.isAnnounced = NO;
        _modeIdentifier = @"SEEMode.Base";
        [self _generateNewSession];
    }
    return self;
}

- (void)dealloc
{
    [_attributedString release];
    
    [_session setDocument:nil];
    if ([_session isServer]) [_session abandon];
    [_session release];
    [_modeIdentifier release];
    
    [super dealloc];
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result setObject:[NSData dataWithUUIDString:[self uniqueID]] forKey:@"FileID"];
    [result setObject:[[self fileURL] path] forKey:@"FilePath"];
    [result setObject:[NSNumber numberWithBool:[self isAnnounced]] forKey:@"IsAnnounced"];
    [result setObject:[NSNumber numberWithInt:[[self session] accessState]] forKey:@"accessState"];
    return result;
}


#pragma mark -

- (NSURL *)fileURL
{
    return _fileURL;
}

- (void)setFileURL:(NSURL *)absoluteURL
{
    [_fileURL autorelease];
    _fileURL = [absoluteURL retain];
}

- (NSString *)modeIdentifier
{
    return _modeIdentifier;
}

- (void)setModeIdentifier:(NSString *)identifier
{
    [_modeIdentifier autorelease];
    if (identifier)
        _modeIdentifier = [identifier copy];
    else
        _modeIdentifier = @"SEEMode.Base";
}

- (void)setSession:(TCMMMSession *)session
{
    [_session autorelease];
    _session = [session retain];
}

- (TCMMMSession *)session
{
    return _session;
}

- (NSString *)uniqueID {
    return [_session sessionID];
}


- (BOOL)isAnnounced
{
    return _flags.isAnnounced;
}

- (void)setIsAnnounced:(BOOL)flag
{
    if ([[self session] isServer]) {
        if (_flags.isAnnounced != flag) {
            _flags.isAnnounced = flag;
            if (_flags.isAnnounced) {
                DEBUGLOG(@"Document", AllLogLevel, @"announce");
                [[TCMMMPresenceManager sharedInstance] announceSession:[self session]];
                [[self session] setFilename:[self preparedDisplayName]];
            } else {
                DEBUGLOG(@"Document", AllLogLevel, @"conceal");
                TCMMMSession *session = [self session];
                [[TCMMMPresenceManager sharedInstance] concealSession:session];
            }
        }
    }
}

- (NSStringEncoding)stringEncoding {
    return _stringEncoding;
}
- (void)setStringEncoding:(NSStringEncoding)anEncoding {
    _stringEncoding = anEncoding;
}


#pragma mark -

- (void)setContentString:(NSString *)aString {
    [_attributedString replaceCharactersInRange:NSMakeRange(0, [_attributedString length])
                                     withString:aString];
}

- (BOOL)readFromURL:(NSURL *)absoluteURL error:(NSError **)outError
{
    NSString *contentString = [[NSString alloc] initWithContentsOfURL:absoluteURL
                                                             encoding:_stringEncoding
                                                                error:outError];
    
    if (contentString) {
        [_attributedString replaceCharactersInRange:NSMakeRange(0, [_attributedString length])
                                         withString:contentString];
        [contentString release];
        return YES;
    }
    
    return NO;
}

- (BOOL)saveToURL:(NSURL *)absoluteURL error:(NSError **)outError
{
    NSString *contentString = [_attributedString string];
    BOOL result = [contentString writeToURL:absoluteURL
                                 atomically:YES
                                   encoding:_stringEncoding
                                      error:outError];
    return result;
}

- (void)changeSelectionOfUserWithID:(NSString *)aUserID toRange:(NSRange)aRange {
    TCMMMUser *user = [[TCMMMUserManager sharedInstance] userForUserID:aUserID];
    NSMutableDictionary *properties = [user propertiesForSessionID:[[self session] sessionID]];
    if (!properties) {
        //NSLog(@"Tried to change selection of user for session in which he isnt");
    } else {
        SelectionOperation *selectionOperation = [properties objectForKey:@"SelectionOperation"];
        if (selectionOperation) {
            [selectionOperation setSelectedRange:aRange];
        } else {
            [properties setObject:[SelectionOperation selectionOperationWithRange:aRange userID:aUserID] forKey:@"SelectionOperation"];
        }
        [self invalidateLayoutForRange:aRange];
    }
}

#pragma mark -

- (NSDictionary *)sessionInformation;
{
    NSLog(@"%s", __FUNCTION__);

    NSMutableDictionary *result=[NSMutableDictionary dictionary];

    [result setObject:[self modeIdentifier] forKey:@"DocumentMode"];

//    DocumentModeLineEndingPreferenceKey = @"LineEnding";
//    DocumentModeTabWidthPreferenceKey   = @"TabWidth";
//    DocumentModeUseTabsPreferenceKey    = @"UseTabs";
//    DocumentModeWrapLinesPreferenceKey  = @"WrapLines";
//    DocumentModeWrapModePreferenceKey   = @"WrapMode";

    [result setObject:[NSNumber numberWithUnsignedInt:LineEndingLF]
               forKey:@"LineEnding"];
    [result setObject:[NSNumber numberWithInt:4]
               forKey:@"TabWidth"];
    [result setObject:[NSNumber numberWithBool:NO]
               forKey:@"UseTabs"];
    [result setObject:[NSNumber numberWithBool:YES]
               forKey:@"WrapLines"];
    [result setObject:[NSNumber numberWithInt:0]
               forKey:@"WrapMode"];

    return result;
}

- (void)sessionDidReceiveKick:(TCMMMSession *)aSession
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)sessionDidReceiveClose:(TCMMMSession *)aSession
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)sessionDidLeave:(TCMMMSession *)aSession
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)sessionDidLoseConnection:(TCMMMSession *)aSession
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)sessionDidAcceptJoinRequest:(TCMMMSession *)aSession
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)sessionDidDenyJoinRequest:(TCMMMSession *)aSession
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)sessionDidCancelInvitation:(TCMMMSession *)aSession
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)session:(TCMMMSession *)aSession didReceiveSessionInformation:(NSDictionary *)aSessionInformation
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)session:(TCMMMSession *)aSession didReceiveContent:(NSDictionary *)aContent
{
    NSLog(@"%s", __FUNCTION__);
}

- (NSString *)preparedDisplayName
{
    NSLog(@"%s", __FUNCTION__);
    if ([self fileURL]) {
        return [[[self fileURL] absoluteString] lastPathComponent];
    } else {
        return @"<Error>";
    }
}

- (void)invalidateLayoutForRange:(NSRange)aRange
{
}

- (NSDictionary *)textStorageDictionaryRepresentation
{
    NSLog(@"%s", __FUNCTION__);

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    [dictionary setObject:[[[_attributedString string] copy] autorelease] forKey:@"String"];
    [dictionary setObject:[NSNumber numberWithUnsignedInt:_stringEncoding] forKey:@"Encoding"];
    NSMutableDictionary *attributeDictionary = [[NSMutableDictionary alloc] init];
    NSEnumerator *attributeNames = [[NSArray arrayWithObjects:WrittenByUserIDAttributeName, ChangedByUserIDAttributeName ,nil] objectEnumerator];
    NSString *attributeName;
    NSRange wholeRange = NSMakeRange(0, [_attributedString length]);
    if (wholeRange.length) {
        while ((attributeName = [attributeNames nextObject])) {
            NSMutableArray *attributeArray = [[NSMutableArray alloc] init];
            NSRange searchRange = NSMakeRange(0,0);
            while (NSMaxRange(searchRange)<wholeRange.length) {
                id value = [_attributedString attribute:attributeName
                                                atIndex:NSMaxRange(searchRange) 
                                  longestEffectiveRange:&searchRange 
                                                inRange:wholeRange];
                if (value) {
                    [attributeArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                        value, @"val",
                        [NSNumber numberWithUnsignedInt:searchRange.location], @"loc",
                        [NSNumber numberWithUnsignedInt:searchRange.length], @"len",
                        nil]];
                }
            }
            if ([attributeArray count]) {
                [attributeDictionary setObject:attributeArray forKey:attributeName];
            }
            [attributeArray release];
        }
    }
    [dictionary setObject:attributeDictionary forKey:@"Attributes"];
    [attributeDictionary release];

    return dictionary;
}

- (void)updateProxyWindow
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)showWindows
{
    NSLog(@"%s", __FUNCTION__);
}

- (NSSet *)userIDsOfContributors
{
    NSLog(@"%s", __FUNCTION__);

    NSMutableSet *result = [NSMutableSet set];

    id userID = nil;
    NSRange attributeRange = NSMakeRange(0, 0);
    while (NSMaxRange(attributeRange) < [_attributedString length]) {
        userID = [_attributedString attribute:WrittenByUserIDAttributeName
                                      atIndex:NSMaxRange(attributeRange)
                               effectiveRange:&attributeRange];
        if (userID) [result addObject:userID];
    }

    return result;
}

- (void)sendInitialUserState
{
    NSLog(@"%s", __FUNCTION__);
    
    TCMMMSession *session = [self session];
    NSString *sessionID = [session sessionID];
    NSEnumerator *writingParticipants = [[[session participants] objectForKey:@"ReadWrite"] objectEnumerator];
    TCMMMUser *user = nil;
    while ((user = [writingParticipants nextObject])) {
        SelectionOperation *selectionOperation = [[user propertiesForSessionID:sessionID] objectForKey:@"SelectionOperation"];
        if (selectionOperation) {
            [session documentDidApplyOperation:selectionOperation];
        }
    }

    [session documentDidApplyOperation:[SelectionOperation selectionOperationWithRange:NSMakeRange(0, 0) userID:[TCMMMUserManager myUserID]]];

}

- (BOOL)isReceivingContent
{
    return NO;
}

- (void)validateEditability
{
    NSLog(@"%s", __FUNCTION__);
}

- (BOOL)handleOperation:(TCMMMOperation *)anOperation
{
    NSLog(@"%s", __FUNCTION__);

    if ([[anOperation operationID] isEqualToString:[TextOperation operationID]]) {

        TextOperation *operation = (TextOperation *)anOperation;
        [_attributedString beginEditing];
        NSRange newRange = NSMakeRange([operation affectedCharRange].location,
                                       [[operation replacementString] length]);
        [_attributedString replaceCharactersInRange:[operation affectedCharRange]
                                         withString:[operation replacementString]];
        [_attributedString addAttribute:WrittenByUserIDAttributeName value:[operation userID]
                                  range:newRange];
        [_attributedString addAttribute:ChangedByUserIDAttributeName value:[operation userID]
                                  range:newRange];
        //[_attributedString addAttributes:[self plainTextAttributes] range:newRange];
        [_attributedString endEditing];


    } else if ([[anOperation operationID] isEqualToString:[SelectionOperation operationID]]){
        [self changeSelectionOfUserWithID:[anOperation userID]
                                  toRange:[(SelectionOperation *)anOperation selectedRange]];
    }
    
    return YES;
}

@end
