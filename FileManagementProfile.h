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
}

- (void)askForDirectoryListing;
- (void)requestNewFileWithAttributes:(NSDictionary *)attributes;

@end

@interface NSObject (FileManagementProfileDelegateAdditions)
- (NSArray *)directoryListingForProfile:(FileManagementProfile *)aProfile;
- (void)profile:(FileManagementProfile *)aProfile didReceiveDirectoryContents:(NSArray *)aContentArray;
- (id)profile:(FileManagementProfile *)aProfile didRequestNewDocumentWithAttributes:(NSDictionary *)attributes error:(NSError **)error;
- (void)profile:(FileManagementProfile *)aProfile didAckNewDocument:(NSDictionary *)aDocumentDictionary;
@end
