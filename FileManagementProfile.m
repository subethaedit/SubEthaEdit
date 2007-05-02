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
    [self registerSelector:@selector(replyToFILLST:) forMessageType:@"MSG" 
                            messageString:@"FILLST" channelRole:TCMBEEPChannelRoleResponder];
    [self registerSelector:@selector(acceptFILLST:) forMessageType:@"RPY" 
                           messageString:@"FILLST" channelRole:TCMBEEPChannelRoleInitiator];
    [self registerSelector:@selector(replyToFILNEW:) forMessageType:@"MSG" 
                            messageString:@"FILNEW" channelRole:TCMBEEPChannelRoleResponder];
    [self registerSelector:@selector(acceptFILACK:) forMessageType:@"RPY" 
                           messageString:@"FILACK" channelRole:TCMBEEPChannelRoleInitiator];
    [self registerSelector:@selector(replyToATTSET:) forMessageType:@"MSG" 
                            messageString:@"ATTSET" channelRole:TCMBEEPChannelRoleResponder];
    [self registerSelector:@selector(acceptSETACKFAI:) forMessageType:@"RPY" 
                           messageString:@"SETACK" channelRole:TCMBEEPChannelRoleInitiator];
    [self registerSelector:@selector(acceptSETACKFAI:) forMessageType:@"ERR" 
                           messageString:@"SETFAI" channelRole:TCMBEEPChannelRoleInitiator];


    [self registerSelector:@selector(replyToFILUPD:) forMessageType:@"MSG" 
                            messageString:@"FILUPD" channelRole:TCMBEEPChannelRoleInitiator];
    [self registerSelector:@selector(acceptUPDACK:) forMessageType:@"RPY" 
                           messageString:@"UPDACK" channelRole:TCMBEEPChannelRoleResponder];
//    NSLog(@"%s %@",__FUNCTION__,[self performSelector:@selector(myRoutingDictionary)]);
}

- (id)initWithChannel:(TCMBEEPChannel *)aChannel {
    if ((self=[super initWithChannel:aChannel])) {
        _didSendFILLST = NO;
    }
    return self;
}

- (BOOL)didSendFILLST {
    return _didSendFILLST;
}

- (void)askForFileList {
    [[self channel] sendMessage:
        [[TCMBEEPBencodedMessage bencodedMessageWithMessageType:@"MSG"
            messageNumber:[[self channel] nextMessageNumber]
            messageString:@"FILLST"
            content:nil] BEEPMessage]];
}

- (void)replyToFILLST:(TCMBEEPBencodedMessage *)aMessage {
    [[self channel] sendMessage:
        [[TCMBEEPBencodedMessage bencodedMessageWithMessageType:@"RPY"
            messageNumber:[aMessage messageNumber]
            messageString:@"FILLST"
            content:[[self delegate] fileListForProfile:self]] BEEPMessage]];
    _didSendFILLST = YES;
}

- (void)acceptFILLST:(TCMBEEPBencodedMessage *)aMessage {
    [[self delegate] profile:self didReceiveFileList:[aMessage content]];
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
    id document = [[self delegate] profile:self didRequestNewDocumentWithAttributes:[aMessage content] error:&error];
    if (document) {
        [[self channel] sendMessage:
            [[TCMBEEPBencodedMessage bencodedMessageWithMessageType:@"RPY"
                messageNumber:[aMessage messageNumber]
                messageString:@"FILACK"
                content:[document dictionaryRepresentation]] BEEPMessage]];
    } else {
        [[self channel] sendMessage:
            [[TCMBEEPBencodedMessage bencodedMessageWithMessageType:@"ERR"
                messageNumber:[aMessage messageNumber]
                messageString:@"FILFAI"
                content:nil] BEEPMessage]];
    }
}

- (void)acceptFILACK:(TCMBEEPBencodedMessage *)aMessage {
    [[self delegate] profile:self didAckNewDocument:[aMessage content]];
}

- (void)changeAttributes:(NSDictionary *)newAttributes forFileWithID:(NSString *)aFileID {
    [[self channel] sendMessage:
        [[TCMBEEPBencodedMessage bencodedMessageWithMessageType:@"MSG"
            messageNumber:[[self channel] nextMessageNumber]
            messageString:@"ATTSET"
            content:[NSDictionary dictionaryWithObjectsAndKeys:aFileID,@"FileID",newAttributes,@"NewAttributes",nil]] BEEPMessage]];
}

- (void)replyToATTSET:(TCMBEEPBencodedMessage *)aMessage {
    NSError *error = nil;
    id document = [[self delegate] profile:self didRequestChangeOfAttributes:[[aMessage content] objectForKey:@"NewAttributes"] ofDocumentWithID:[[aMessage content] objectForKey:@"FileID"] error:&error];
    if (!error) {
        [[self channel] sendMessage:
            [[TCMBEEPBencodedMessage bencodedMessageWithMessageType:@"RPY"
                messageNumber:[aMessage messageNumber]
                messageString:@"SETACK"
                content:[document dictionaryRepresentation]] BEEPMessage]];
    } else {
        [[self channel] sendMessage:
            [[TCMBEEPBencodedMessage bencodedMessageWithMessageType:@"ERR"
                messageNumber:[aMessage messageNumber]
                messageString:@"SETFAI"
                content:[document dictionaryRepresentation]] BEEPMessage]];
    }
}

- (void)acceptSETACKFAI:(TCMBEEPBencodedMessage *)aMessage {
    [[self delegate] profile:self didAcceptSetResponse:[aMessage content] wasFailure:[[aMessage BEEPMessage] isERR]];
}

- (void)sendFileUpdates:(NSDictionary *)fileUpdateDictionary {
    [[self channel] sendMessage:
        [[TCMBEEPBencodedMessage bencodedMessageWithMessageType:@"MSG"
            messageNumber:[[self channel] nextMessageNumber]
            messageString:@"FILUPD"
            content:fileUpdateDictionary] BEEPMessage]];
}

- (void)replyToFILUPD:(TCMBEEPBencodedMessage *)aMessage {
    [[self channel] sendMessage:
        [[TCMBEEPBencodedMessage bencodedMessageWithMessageType:@"RPY"
            messageNumber:[aMessage messageNumber]
            messageString:@"UPDACK"
            content:nil] BEEPMessage]];
    [[self delegate] profile:self didReceiveFileUpdates:[aMessage content]];
}

- (void)acceptUPDACK:(TCMBEEPBencodedMessage *)aMessage {
}


@end
