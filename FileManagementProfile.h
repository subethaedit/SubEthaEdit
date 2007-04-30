//
//  FileManagementProfile.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 25.04.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCMBEEP/TCMBEEP.h"


@interface FileManagementProfile : TCMBEEPBencodingProfile {
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


@interface NSObject (FileManagementProfileInitiatorDelegateAdditions)
- (void)profile:(FileManagementProfile *)aProfile didReceiveFileList:(NSArray *)aContentArray;
- (void)profile:(FileManagementProfile *)aProfile didReceiveFileUpdates:(NSDictionary *)aFileUpdateDictionary;
- (void)profile:(FileManagementProfile *)aProfile didAckNewDocument:(NSDictionary *)aDocumentDictionary;
- (void)profile:(FileManagementProfile *)aProfile didAcceptSetResponse:(NSDictionary *)aDocumentDictionary wasFailure:(BOOL)aFailure;
@end


@interface NSObject (FileManagementProfileResponderDelegateAdditions)
- (NSArray *)fileListForProfile:(FileManagementProfile *)aProfile;
- (id)profile:(FileManagementProfile *)aProfile didRequestNewDocumentWithAttributes:(NSDictionary *)attributes error:(NSError **)outError;
- (id)profile:(FileManagementProfile *)aProfile didRequestChangeOfAttributes:(NSDictionary *)aNewAttributes ofDocumentWithID:(NSString *)aFileID error:(NSError **)outError;
@end
