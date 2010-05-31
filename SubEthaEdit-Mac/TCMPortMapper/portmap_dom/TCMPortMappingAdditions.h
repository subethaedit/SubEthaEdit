//
//  TCMPortMappingAdditions.h
//  Port Map
//
//  Created by Dominik Wagner on 07.02.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <TCMPortMapper/TCMPortMapper.h>

@interface TCMPortMapping (TCMPortMappingAdditions)

+ (TCMPortMapping*)portMappingWithDictionaryRepresentation:(NSDictionary *)aDictionary;
- (NSDictionary *)dictionaryRepresentation;

@end
