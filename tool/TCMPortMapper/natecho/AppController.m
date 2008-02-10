//
//  AppController.m
//  Port Map
//
//  Created by Dominik Wagner on 10.02.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "AppController.h"
#import <TCMPortMapper/TCMPortMapper.h>

@implementation AppController

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    TCMPortMapper *pm = [TCMPortMapper sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:O_publicIndicator selector:@selector(startAnimation:) name:TCMPortMapperDidStartWorkNotification object:pm];
    [[NSNotificationCenter defaultCenter] addObserver:O_publicIndicator selector:@selector(stopAnimation:) name:TCMPortMapperDidEndWorkNotification object:pm];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMappingStatus:) name:TCMPortMappingDidChangeMappingStatusNotification object:nil];
    I_server = [TCPServer new];
    [I_server setType:@"_echo._tcp."];
    [I_server setName:@"NATEcho"];
    [I_server setDelegate:self];
    I_streamsArray = [NSMutableArray new];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self stop];
}

- (void)start {
    int port = [O_portTextField intValue];
    [I_server setPort:port];
    NSError *error = nil;
    if ([I_server start:&error]) {
        [O_serverStatusImageView setImage:[NSImage imageNamed:@"DotGreen"]];
        [O_serverStatusTextField setStringValue:@"Running"];
        [O_serverReachabilityTextField setStringValue:[NSString stringWithFormat:@"telnet %@ %d",[[TCMPortMapper sharedInstance] localIPAddress],port]];
    
        TCMPortMapper *pm = [TCMPortMapper sharedInstance];
        // because the port is an option we need to add a new port mapping each time
        // and remove it afterwards. if it was fixed we could add the port mapping in preparation 
        // and just start or stop the port mapper
        [pm addPortMapping:[TCMPortMapping portMappingWithPrivatePort:port desiredPublicPort:port userInfo:nil]];
        [pm start];
    } else {
        NSLog(@"%s %@",__FUNCTION__,error);
    }
}

- (void)stop {
    [I_server stop];
    [O_serverStatusImageView setImage:[NSImage imageNamed:@"DotRed"]];
    [O_serverStatusTextField setStringValue:@"Stopped"];
    TCMPortMapper *pm = [TCMPortMapper sharedInstance];
    // we know that we just added one port mapping so let us remove it
    [O_serverReachabilityTextField setStringValue:@"Not running"];
    [pm removePortMapping:[[pm portMappings] anyObject]];
    // stop also stops the current mappings, but it stores the mappings
    // so you could start again and get the same mappings
    [pm stop];
}

- (IBAction)startStop:(id)aSender {
    if ([O_portTextField isEnabled]) {
        [O_portTextField setEnabled:NO];
        [O_startStopButton setTitle:@"Stop"];
        [self start];
    } else {
        [O_portTextField setEnabled:YES];
        [O_startStopButton setTitle:@"Start"];
        [self stop];
    }
}

- (void)updateMappingStatus:(NSNotification *)aNotification {
    NSLog(@"%s %@",__FUNCTION__,[aNotification object]);
    TCMPortMapping *aMapping = [aNotification object];
    if ([aMapping mappingStatus] == TCMPortMappingStatusUnmapped) {
        [O_publicStatusImageView setImage:[NSImage imageNamed:@"DotRed"]];
        [O_publicStatusTextField setStringValue:@"Unreachable"];
    } else if ([aMapping mappingStatus] == TCMPortMappingStatusTrying) {
        [O_publicStatusImageView setImage:[NSImage imageNamed:@"DotYellow"]];
        [O_publicStatusTextField setStringValue:@"Trying..."];
    } else if ([aMapping mappingStatus] == TCMPortMappingStatusMapped) {
        [O_publicStatusImageView setImage:[NSImage imageNamed:@"DotGreen"]];
        [O_publicStatusTextField setStringValue:[NSString stringWithFormat:@"telnet %@ %d",[[TCMPortMapper sharedInstance] externalIPAddress],[aMapping publicPort]]];
    }
}

// the code below is bad unfinished network code which barely suffices for the echo example, but leaks and does other weird stuff

- (void)TCPServer:(TCPServer *)server didReceiveConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr {
    NSLog(@"%s",__FUNCTION__);
    [istr setDelegate:self];
    [istr scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:(id)kCFRunLoopCommonModes];
    [ostr scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:(id)kCFRunLoopCommonModes];
    [I_streamsArray addObject:istr];
    [I_streamsArray addObject:ostr];
    [istr open];
    [ostr open];
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    NSLog(@"%s %@ %d",__FUNCTION__,theStream,streamEvent);
    NSInputStream *inputStream = (NSInputStream *)theStream;
    switch(streamEvent) {
    case NSStreamEventHasBytesAvailable:
        if ([inputStream hasBytesAvailable]) {
            unsigned char buffer[4097];
            int length = [inputStream read:buffer maxLength:4096];
            if (length) {
                buffer[length]=0;
                NSLog(@"%s %s",__FUNCTION__,buffer);
                NSOutputStream *outputStream = [I_streamsArray objectAtIndex:[I_streamsArray indexOfObjectIdenticalTo:inputStream]+1];
                [outputStream write:buffer maxLength:length];
            }
        }
        break;
    }
}

@end
