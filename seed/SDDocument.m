//
//  SDDocument.m
//  SubEthaEdit
//
//  Created by Martin Ott on 3/23/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "SDDocument.h"
#import "SDDocumentManager.h"
#import "../TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "../SelectionOperation.h"
#import "../TextOperation.h"


NSString * const WrittenByUserIDAttributeName = @"WrittenByUserID";
NSString * const ChangedByUserIDAttributeName = @"ChangedByUserID";

NSString * const SDDocumentDidChangeChangeCountNotification = @"SDDocumentDidChangeChangeCountNotification";

@implementation SDDocument

- (void)updateChangeCount {
    _changeCount++;
    [[NSNotificationQueue defaultQueue]
    enqueueNotification:[NSNotification notificationWithName:SDDocumentDidChangeChangeCountNotification object:self]
           postingStyle:NSPostWhenIdle
           coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
               forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}
 
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

- (id)initWithURL:(NSURL *)absoluteURL onDisk:(BOOL)aFlag {
    if ((self = [self init])) {
        [self setFileURL:absoluteURL];
        _flags.onDisk = aFlag;
    }
    return self;
}

- (BOOL)readFromDisk:(NSError **)outError {
    return [self readFromURL:[self fileURL] error:outError];
}

- (BOOL)writeToDisk:(NSError **)outError {
    return [self writeToURL:[self fileURL] error:outError];
}


- (id)init
{
    self = [super init];
    if (self) {
        _stringEncoding = NSUTF8StringEncoding;
        _attributedString = [[NSMutableAttributedString alloc] init];
        _flags.isAnnounced = NO;
        _flags.onDisk = NO;
        _modeIdentifier = @"SEEMode.Base";
        [self _generateNewSession];
        _changeCount = 0;
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
    [result setObject:[self uniqueID]                      forKey:@"FileID"];
    [result setObject:[self pathRelativeToDocumentRoot]    forKey:@"FilePath"];
    [result setObject:[self valueForKey:@"changeCount"]    forKey:@"ChangeCount"];
    [result setObject:[self valueForKey:@"isAnnounced"]    forKey:@"IsAnnounced"];
    [result setObject:[self valueForKey:@"accessState"]    forKey:@"AccessState"];
    [result setObject:[self valueForKey:@"modeIdentifier"] forKey:@"ModeIdentifier"];
    [result setObject:(NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding([self stringEncoding])) forKey:@"Encoding"];
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
    [self updateChangeCount];
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

- (void)setUniqueID:(NSString *)aUUIDString {
    [[TCMMMPresenceManager sharedInstance] unregisterSession:[self session]];
    [[self retain] autorelease];
    [(SDDocumentManager *)[SDDocumentManager sharedInstance] removeDocument:self];
    [_session setSessionID:aUUIDString];
    [(SDDocumentManager *)[SDDocumentManager sharedInstance] addDocument:self];
    [[TCMMMPresenceManager sharedInstance]   registerSession:[self session]];
}

- (NSString *)uniqueID {
    return [_session sessionID];
}


- (BOOL)isAnnounced
{
    return _flags.isAnnounced;
}

- (BOOL)setIsAnnounced:(BOOL)flag
{
    if (flag && _flags.onDisk && [_attributedString length]==0) {
        if (![self readFromDisk:nil]) return NO;
    }
    if (_flags.isAnnounced != flag) {
        _flags.isAnnounced = flag;
        if (_flags.isAnnounced) {
            DEBUGLOG(@"Document", AllLogLevel, @"announce");
            [[self session] setFilename:[self preparedDisplayName]];
            [[TCMMMPresenceManager sharedInstance] announceSession:[self session]];
        } else {
            DEBUGLOG(@"Document", AllLogLevel, @"conceal");
            TCMMMSession *session = [self session];
            [[TCMMMPresenceManager sharedInstance] concealSession:session];
        }
    }
    [self updateChangeCount];
    return YES;
}

- (NSStringEncoding)stringEncoding {
    return _stringEncoding;
}
- (BOOL)setStringEncoding:(NSStringEncoding)anEncoding {
    _stringEncoding = anEncoding;
    [self updateChangeCount];
    return YES;
    #warning TODO: check if is announced / and if the Attributed String contents can be encoded in the encoding set
}

- (void)setAccessState:(TCMMMSessionAccessState)aState {
    [[self session] setAccessState:aState];
    [self updateChangeCount];
}
- (TCMMMSessionAccessState)accessState {
    return [[self session] accessState];
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

- (BOOL)writeToURL:(NSURL *)absoluteURL error:(NSError **)outError
{
    #warning TODO: generate potential subdirectories
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
    //NSLog(@"%s", __FUNCTION__);

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
    //NSLog(@"%s", __FUNCTION__);
}

- (void)sessionDidReceiveClose:(TCMMMSession *)aSession
{
    //NSLog(@"%s", __FUNCTION__);
}

- (void)sessionDidLeave:(TCMMMSession *)aSession
{
    //NSLog(@"%s", __FUNCTION__);
}

- (void)sessionDidLoseConnection:(TCMMMSession *)aSession
{
    //NSLog(@"%s", __FUNCTION__);
}

- (void)sessionDidAcceptJoinRequest:(TCMMMSession *)aSession
{
    //NSLog(@"%s", __FUNCTION__);
}

- (void)sessionDidDenyJoinRequest:(TCMMMSession *)aSession
{
    //NSLog(@"%s", __FUNCTION__);
}

- (void)sessionDidCancelInvitation:(TCMMMSession *)aSession
{
    //NSLog(@"%s", __FUNCTION__);
}

- (void)session:(TCMMMSession *)aSession didReceiveSessionInformation:(NSDictionary *)aSessionInformation
{
    //NSLog(@"%s", __FUNCTION__);
}

- (void)session:(TCMMMSession *)aSession didReceiveContent:(NSDictionary *)aContent
{
    //NSLog(@"%s", __FUNCTION__);
}

- (NSString *)pathRelativeToDocumentRoot {
    if ([self fileURL]) {
        NSArray *rootPathComponents = [[[SDDocumentManager sharedInstance] documentRootPath] pathComponents];
        NSArray *myComponents = [[[self fileURL] path] pathComponents];
        return [NSString pathWithComponents:[myComponents objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange([rootPathComponents count],[myComponents count]-[rootPathComponents count])]]];
    } else {
        return @"<Error>";
    }
}

- (NSString *)preparedDisplayName {
    return [self pathRelativeToDocumentRoot];
}

- (void)invalidateLayoutForRange:(NSRange)aRange
{
}

- (NSDictionary *)textStorageDictionaryRepresentation
{
    //NSLog(@"%s", __FUNCTION__);

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
    //NSLog(@"%s", __FUNCTION__);
}

- (void)showWindows
{
    //NSLog(@"%s", __FUNCTION__);
}

- (NSSet *)userIDsOfContributors
{
    //NSLog(@"%s", __FUNCTION__);

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
        NSRange newRange = NSMakeRange([operation  affectedCharRange].location,
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

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ dictionaryRep:%@",[super description],[[self dictionaryRepresentation] description]];
}

@end
