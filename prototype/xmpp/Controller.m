//
//  Controller.m
//  xmpp
//
//  Created by Martin Ott on Tue Nov 11 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import "Controller.h"
#import "XMLStream.h"

@implementation Controller

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:NSFileHandleReadCompletionNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [I_XMLStream release];
    [super dealloc];
}

- (void)setXMLStream:(XMLStream *)aXMLStream
{
    [I_XMLStream autorelease];
    I_XMLStream = [aXMLStream retain];
}

- (XMLStream *)XMLStream
{
    return I_XMLStream;
}

- (void)dataAvailable:(NSNotification *)aNotification
{
    NSData *input = [[aNotification userInfo] objectForKey:@"NSFileHandleNotificationDataItem"];
    NSMutableString *inputString = [[[NSMutableString alloc] initWithData:input encoding:NSUTF8StringEncoding] autorelease];
    [inputString deleteCharactersInRange:NSMakeRange([inputString length]-1, 1)];
    
    NSArray *params = [inputString componentsSeparatedByString:@" "];
    if ([params count] == 0) {
        fprintf(stdout, "xmpp> ");
        fflush(stdout);
        return;
    }
    
    NSString *command = [params objectAtIndex:0];
    if (([command isEqualToString:@"quit"]) || ([command isEqualToString:@"q"]) || ([command isEqualToString:@"q"]) || ([command isEqualToString:@"exit"])) {
        [self quit];
        return;
    } else if ([command isEqualToString:@"connect"]) {
        if ([params count] == 2) {
            NSString *name = [params objectAtIndex:1];
            NSHost *host = [NSHost hostWithName:name];
            //NSLog(@"Host: %@", [host description]);
            I_XMLStream = [XMLStream new];
            [I_XMLStream connectToHost:host];
            NSString *startElement = [NSString stringWithFormat:@"<?xml version=\"1.0\"?><stream:stream xmlns:stream=\"http://etherx.jabber.org/streams\" to=\"%@\" xmlns=\"jabber:client\">", name];
            [I_XMLStream writeData:[startElement dataUsingEncoding:NSUTF8StringEncoding]];
        } else {
            fprintf(stdout, "Usage: connect <host>\n");
            fprintf(stdout, "xmpp> ");
            fflush(stdout);
        }
    } else if ([command isEqualToString:@"login"]) {
        if ([params count] == 3) {
            NSString *username = [params objectAtIndex:1];
            NSString *password = [params objectAtIndex:2];
            NSString *loginStanza = [NSString stringWithFormat:@"<iq type=\"set\"><query xmlns=\"jabber:iq:auth\"><username>%@</username><password>%@</password><resource>xmpp</resource></query></iq>", username, password];
            [I_XMLStream writeData:[loginStanza dataUsingEncoding:NSUTF8StringEncoding]];
        } else {
            fprintf(stdout, "Usage: login <username> <password>\n");
            fprintf(stdout, "xmpp> ");
            fflush(stdout);
        }
    } else {
        fprintf(stdout, "Unknown command\n");
        fprintf(stdout, "xmpp> ");
        fflush(stdout);
    }
    
    [[aNotification object] readInBackgroundAndNotify];
}

- (void)quit
{
    endRunLoop = YES;
}


@end
