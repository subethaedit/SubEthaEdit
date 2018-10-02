//  SEENetworkDocumentRepresentation.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.02.14.

#import <Foundation/Foundation.h>
#import "SEEDocumentListItemProtocol.h"

@class TCMMMSession, TCMMMUser;

@interface SEENetworkDocumentListItem : NSObject <SEEDocumentListItem>
@property (nonatomic, strong) TCMBEEPSession *beepSession;
@property (nonatomic, strong) TCMMMSession *documentSession;

@property (nonatomic, strong) NSImage *documentAccessStateImage;

@end
