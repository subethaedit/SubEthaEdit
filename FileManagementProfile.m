//
//  FileManagementProfile.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 25.04.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "FileManagementProfile.h"


@implementation FileManagementProfile

+ (void)initialize {
    [self registerSelector:@selector(replyToDIRLST:) forMessageType:@"MSG" 
                            messageString:@"DIRLST" channelRole:TCMBEEPChannelRoleResponder];
    [self registerSelector:@selector(acceptDIRCON:) forMessageType:@"RPY" 
                           messageString:@"DIRCON" channelRole:TCMBEEPChannelRoleInitiator];
    [self registerSelector:@selector(replyToFILNEW:) forMessageType:@"MSG" 
                            messageString:@"FILNEW" channelRole:TCMBEEPChannelRoleResponder];
    NSLog(@"%s %@",__FUNCTION__,[self performSelector:@selector(myRoutingDictionary)]);
}

- (void)askForDirectoryListing {
    [[self channel] sendMessage:
        [[TCMBEEPBencodedMessage bencodedMessageWithMessageType:@"MSG"
            messageNumber:[[self channel] nextMessageNumber]
            messageString:@"DIRLST"
            content:nil] BEEPMessage]];
}

- (void)replyToDIRLST:(TCMBEEPBencodedMessage *)aMessage {
    [[self channel] sendMessage:
        [[TCMBEEPBencodedMessage bencodedMessageWithMessageType:@"RPY"
            messageNumber:[aMessage messageNumber]
            messageString:@"DIRCON"
            content:[[self delegate] directoryListingForProfile:self]] BEEPMessage]];
}

- (void)acceptDIRCON:(TCMBEEPBencodedMessage *)aMessage {
    NSLog(@"%s %@",__FUNCTION__,aMessage);
}

- (void)requestNewFileWithAttributes:(NSDictionary *)attributes {
    [[self channel] sendMessage:
        [[TCMBEEPBencodedMessage bencodedMessageWithMessageType:@"MSG"
            messageNumber:[[self channel] nextMessageNumber]
            messageString:@"FILNEW"
            content:attributes] BEEPMessage]];
}

- (void)replyToFILNEW:(TCMBEEPBencodedMessage *)aMessage {
    NSError *error = nil;
    if ([[self delegate] profile:self didRequestNewDocumentWithAttributes:[aMessage content] error:&error]) {
        TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:[NSData data]];
        [[self channel] sendMessage:[message autorelease]];
    } else {
        TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"ERR" messageNumber:[aMessage messageNumber] payload:[NSData data]];
        [[self channel] sendMessage:[message autorelease]];
    }
}




@end
