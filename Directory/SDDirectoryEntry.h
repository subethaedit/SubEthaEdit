//
//  SDDirectoryEntry.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 07.05.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SDDirectory, SDDirectoryGroup;

@interface SDDirectoryEntry : NSObject {
    SDDirectory *_directory;
    NSString *_shortName;
    NSString *_fullName;
    NSMutableSet *_groups; // the groups this entry is *in*
}

- (id)initWithShortName:(NSString *)aShortName directory:(SDDirectory *)aDirectory;
- (void)addToGroup:(SDDirectoryGroup *)aGroup;
- (void)removeFromGroup:(SDDirectoryGroup *)aGroup;
- (BOOL)isMemberOfGroup:(SDDirectoryGroup *)aGroup;
- (NSString *)shortName;
- (NSString *)fullName;
- (void)setFullName:(NSString *)aString;
- (void)updateWithDictionaryRepresentation:(NSDictionary *)aRepresentation;

@end
