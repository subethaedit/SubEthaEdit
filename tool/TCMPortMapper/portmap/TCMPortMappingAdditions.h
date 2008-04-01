//
//  TCMPortMappingAdditions.h
//
//  Copyright (c) 2007-2008 TheCodingMonkeys: 
//  Martin Pittenauer, Dominik Wagner, <http://codingmonkeys.de>
//  Some rights reserved: <http://opensource.org/licenses/mit-license.php> 
//

#import <Cocoa/Cocoa.h>
#import <TCMPortMapper/TCMPortMapper.h>

@interface TCMPortMapping (TCMPortMappingAdditions)

+ (TCMPortMapping*)portMappingWithDictionaryRepresentation:(NSDictionary *)aDictionary;
- (NSDictionary *)dictionaryRepresentation;

@end
