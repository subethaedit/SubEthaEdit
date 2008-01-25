//
//  TCMPortMapper.h
//  PortMapper
//
//  Created by Martin Pittenauer on 15.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <errno.h>
#import <string.h>
#import <unistd.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@interface TCMPortMapper : NSObject {

}

+ (TCMPortMapper *)sharedInstance;
- (void) mapPublicPort:(int)publicPort toPrivatePort:(int)privatePort withLifetime:(int)seconds;
- (void) mapPublicPort:(int)publicPort toPrivatePort:(int)privatePort;
- (void) mapPort:(int)publicPort;
- (NSString*) externalIPAddress;

@end
