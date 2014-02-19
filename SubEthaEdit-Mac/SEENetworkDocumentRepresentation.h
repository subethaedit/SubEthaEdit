//
//  SEENetworkDocumentRepresentation.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@class  TCMMMSession, TCMMMUser;

@interface SEENetworkDocumentRepresentation : NSObject
@property (nonatomic, weak) TCMMMUser *documentOwner;
@property (nonatomic, weak) TCMMMSession *documentSession;

@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSImage *fileIcon;

- (IBAction)joinDocument:(id)sender;

@end
