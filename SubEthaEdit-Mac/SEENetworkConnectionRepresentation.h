//
//  SEENetworkConnectionRepresentation.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 26.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SEEConnection;

@interface SEENetworkConnectionRepresentation : NSObject

@property (nonatomic, weak) SEEConnection *connection;

@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) NSImage *image;

@end
