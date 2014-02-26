//
//  SEENetworkDocumentRepresentation.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TCMMMSession, TCMMMUser;

@interface SEENetworkDocumentRepresentation : NSObject

@property (nonatomic, weak) TCMMMSession *documentSession;

@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) NSImage *image;

- (IBAction)openDocument:(id)sender;

@end
