//
//  TCMBEEPChannel.m
//  BEEPSample
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPChannel.h"
#import "TCMBEEPSession.h"
#import "TCMBEEPFrame.h"
#import "TCMBEEPMessage.h"
#import "TCMBEEPManagementProfile.h"

static NSMutableDictionary *profileURIToClassMapping;

@implementation TCMBEEPChannel

/*"Initializes the class before it’s used. See NSObject."*/

+ (void)initialize {
    profileURIToClassMapping=[NSMutableDictionary new];
    [self setClass:[TCMBEEPManagementProfile class] forProfileURI:kTCMBEEPManagementProfile];
}

/*""*/
+ (NSDictionary *)profileURIToClassMapping {
    return profileURIToClassMapping;
}

/*""*/
+ (void)setClass:(Class)aClass forProfileURI:(NSString *)aProfileURI {
    [profileURIToClassMapping setObject:aClass forKey:aProfileURI];
}

/*""*/
- (id)initWithSession:(TCMBEEPSession *)aSession number:(unsigned long)aNumber profileURI:(NSString *)aProfileURI
{
    self = [super init];
    if (self) {
        Class profileClass=nil;
        if (profileClass=[[TCMBEEPChannel profileURIToClassMapping] objectForKey:aProfileURI]) {
            I_profile=[[profileClass alloc] initWithChannel:self];
            [self setSession:aSession];
            [self setNumber:aNumber];
            [self setProfileURI:aProfileURI];
            I_currentReadFrame=nil;
            I_currentReadMessage=nil;
            I_messageNumbersWithPendingReplies=[NSMutableIndexSet new];
            I_inboundMessageNumbersWithPendingReplies=[NSMutableIndexSet new];
        }
    }
    
    return self;
}

- (void)dealloc
{
    [I_profileURI release];
    [I_profile release];
    [I_currentReadFrame   release];
    [I_currentReadMessage release];
    [I_messageNumbersWithPendingReplies release];
    [I_inboundMessageNumbersWithPendingReplies release];
    [super dealloc];
}

- (void)setCurrentReadFrame:(TCMBEEPFrame *)aFrame {
    [I_currentReadFrame autorelease];
     I_currentReadFrame = [aFrame retain];
}

- (TCMBEEPFrame *)currentReadFrame {
    return I_currentReadFrame;
}

- (void)setCurrentReadMessage:(TCMBEEPMessage *)aMessage {
    [I_currentReadMessage autorelease];
     I_currentReadMessage = [aMessage retain];
}

- (TCMBEEPMessage *)currentReadMessage {
    return I_currentReadMessage;
}


/*""*/
- (void)setNumber:(unsigned long)aNumber
{
    I_number = aNumber;
}

/*""*/
- (unsigned long)number
{
    return I_number;
}

/*""*/
- (void)setSession:(TCMBEEPSession *)aSession
{
    I_session = aSession;
}

/*""*/
- (TCMBEEPSession *)session
{
    return I_session;
}

/*""*/
- (void)setProfileURI:(NSString *)aProfileURI
{
    [I_profileURI autorelease];
    I_profileURI = [aProfileURI copy];
}

/*""*/
- (NSString *)profileURI
{
    return I_profileURI;
}

/*""*/
- (id)profile {
    return I_profile;
}

- (BOOL)acceptFrame:(TCMBEEPFrame *)aFrame
{
    char *messageType=[aFrame messageType];
    TCMBEEPFrame *currentReadFrame=[self currentReadFrame];
    
    BOOL accept=YES;
    
    
    // 4ter Punkt 2.2.1.1
    if (strcmp([aFrame messageType],"MSG")==0 &&
        [I_inboundMessageNumbersWithPendingReplies containsIndex:[aFrame messageNumber]]) {
        NSLog(@"4ter punkt 2.2.1.1");
        accept = NO;
    }
    
    // 5ter punkt 2.2.1.1
    if ((strcmp(messageType,"MSG")!=0)) {
        if (![I_messageNumbersWithPendingReplies containsIndex:[aFrame messageNumber]]
            && !([aFrame channelNumber]==0 && strcmp([aFrame messageType],"RPY")==0 &&
                 [aFrame messageNumber]==0)) {
            NSLog(@"5ter punkt 2.2.1.1");
            accept = NO;
        }
        
    }
    
    // 8ter punkt 2.2.1.1
    if (strcmp(messageType,"NUL")==0) {
        if ([self currentReadFrame] && !(strcmp([[self currentReadFrame] messageType],"ANS")==0)) {
            // ERROR
            NSLog(@"8ter punkt 2.2.1.1");
            accept = NO;
        }
    }

    // 9ter punkt 2.2.1.1
    if (currentReadFrame && [currentReadFrame isIntermediate]) {
        if ([aFrame messageNumber]!=[currentReadFrame messageNumber])  {
            NSLog(@"9ter punkt 2.2.1.1");
            accept = NO;
        }
    }

    // 10ter punkt 2.2.1.1 (Check sequence numbers)
    if (currentReadFrame) {
        if ([currentReadFrame isIntermediate] ||
            strcmp([currentReadFrame messageType],"ANS") == 0 &&
            strcmp([aFrame messageType],"ANS") == 0) {
            if ([aFrame sequenceNumber]!=
                [currentReadFrame sequenceNumber]+[currentReadFrame length]) {
                // ERROR
                NSLog(@"10ter punkt 2.2.1.1 (Check sequence numbers)");
                accept = NO;
            }
        }
    }
    
    
    
    [self setCurrentReadFrame:aFrame];
    return accept;
}

@end

