//
//  NSURLRequestPostAdditions.h
//  BugShelfTest
//
//  Created by Martin Pittenauer on 25.08.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSURLRequest (POSTAdditions) 
+ (id)requestWithURL:(NSURL *)theURL postDictionary:(NSDictionary *)theDictionary;

@end
