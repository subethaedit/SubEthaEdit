//
//  TCMMMUser.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCMMMUser : NSObject {
    NSMutableDictionary *I_properties;
    NSString *I_ID;
    NSString *I_serviceName;
    NSString *I_name;
}

- (NSMutableDictionary *)properties;

- (void)setID:(NSString *)aID;
- (NSString *)ID;
- (void)setServiceName:(NSString *)aServiceName;
- (NSString *)serviceName;
- (void)setName:(NSString *)aName;
- (NSString *)name;

@end
