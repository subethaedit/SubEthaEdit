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
    [self registerSelector:@selector(replyToDIRLST:) forMessageType:@"MSG" messageString:@"DIRLST" channelRole:TCMBEEPChannelRoleResponder];
    [self registerSelector:@selector(acceptDIRCON:) forMessageType:@"RPY" messageString:@"DIRCON" channelRole:TCMBEEPChannelRoleInitiator];
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
            content:[NSArray arrayWithObjects:@"hallo",@"gallo",nil]] BEEPMessage]];
}

- (void)acceptDIRCON:(TCMBEEPBencodedMessage *)aMessage {
    NSLog(@"%s %@",__FUNCTION__,aMessage);
}


@end
