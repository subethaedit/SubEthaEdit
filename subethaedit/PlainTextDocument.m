//
//  MyDocument.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Feb 24 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "PlainTextDocument.h"
#import "PlainTextWindowController.h"


@implementation PlainTextDocument

- (id)init
{
    self = [super init];
    if (self) {
    
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
        [self setSession:[[TCMMMSession alloc] initWithDocument:self]];
        [[TCMMMPresenceManager sharedInstance] registerSession:[self session]];
    
    }
    return self;
}

- (void)dealloc {
    if (I_flags.isAnnounced) {
        [[TCMMMPresenceManager sharedInstance] concealSession:[self session]];
    }
    [[TCMMMPresenceManager sharedInstance] unregisterSession:[self session]];
    [I_session release];
}

- (void)setSession:(TCMMMSession *)aSession
{
    [I_session autorelease];
    I_session = [aSession retain];
}

- (TCMMMSession *)session
{
    return I_session;
}

- (IBAction)announce:(id)aSender {
    DEBUGLOG(@"Document", 5, @"announce");
    [[TCMMMPresenceManager sharedInstance] announceSession:[self session]];
    I_flags.isAnnounced=YES;
}

- (IBAction)conceal:(id)aSender {
    DEBUGLOG(@"Document", 5, @"conceal");
    [[TCMMMPresenceManager sharedInstance] concealSession:[self session]];
    I_flags.isAnnounced=NO;
}

- (void)makeWindowControllers {
    DEBUGLOG(@"blah",5,@"makeWindowCotrollers");
    [self addWindowController:[[PlainTextWindowController new] autorelease]];
}

- (void)windowControllerWillLoadNib:(NSWindowController *) aController
{
    [super windowControllerWillLoadNib:aController];
    DEBUGLOG(@"blah",5,@"Willload");
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}


- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    DEBUGLOG(@"blah",5,@"didload");
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    // Insert code here to write your document from the given data.  You can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
    return nil;
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
    // Insert code here to read your document from the given data.  You can also choose to override -loadFileWrapperRepresentation:ofType: or -readFromFile:ofType: instead.
    return YES;
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    SEL selector=[anItem action];
    if (selector==@selector(announce:)) {
        return !I_flags.isAnnounced;
    } else if (selector==@selector(conceal:)) {
        return I_flags.isAnnounced;
    }
    return [super validateMenuItem:anItem];
}

@end
