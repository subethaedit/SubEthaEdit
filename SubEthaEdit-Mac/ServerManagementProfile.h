//
//  ServerManagementProfile.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 25.04.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCMBEEP/TCMBEEP.h"


@interface ServerManagementProfile : TCMBEEPBencodingProfile {
    BOOL _didSendFILLST;
}


#pragma mark ### initiator (client) methods ###
- (void)changeAttributes:(NSDictionary *)newAttributes forFileWithID:(NSString *)aFileID;
- (void)askForFileList;
- (void)requestNewFileWithAttributes:(NSDictionary *)attributes;

#pragma mark ### responder (server) methods ###
- (BOOL)didSendFILLST;
- (void)sendFileUpdates:(NSDictionary *)fileUpdateDictionary;

@end


@interface NSObject (ServerManagementProfileInitiatorDelegateAdditions)
- (void)profile:(ServerManagementProfile *)aProfile didReceiveFileList:(NSArray *)aContentArray;
- (void)profile:(ServerManagementProfile *)aProfile didReceiveFileUpdates:(NSDictionary *)aFileUpdateDictionary;
- (void)profile:(ServerManagementProfile *)aProfile didAckNewDocument:(NSDictionary *)aDocumentDictionary;
- (void)profile:(ServerManagementProfile *)aProfile didAcceptSetResponse:(NSDictionary *)aDocumentDictionary wasFailure:(BOOL)aFailure;
@end


@interface NSObject (ServerManagementProfileResponderDelegateAdditions)
- (NSArray *)fileListForProfile:(ServerManagementProfile *)aProfile;
- (id)profile:(ServerManagementProfile *)aProfile didRequestNewDocumentWithAttributes:(NSDictionary *)attributes error:(NSError **)outError;
- (id)profile:(ServerManagementProfile *)aProfile didRequestChangeOfAttributes:(NSDictionary *)aNewAttributes ofDocumentWithID:(NSString *)aFileID error:(NSError **)outError;
@end
