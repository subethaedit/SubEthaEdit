//
//  SDDirectoryUser.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 07.05.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SDDirectoryEntry.h"

@interface SDDirectoryUser : SDDirectoryEntry {
    NSString *_password;
    NSString *_role;
}

- (NSString *)role;
- (NSString *)password;

@end
