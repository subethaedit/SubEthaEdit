//
//  TCMBEEPSessionXMLParser.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 14.10.13.
//  Copyright (c) 2013 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCMBEEPSessionXMLParser : NSObject <NSXMLParserDelegate>

@property (atomic, readonly, strong) NSString *elementName;
@property (atomic, readonly, strong) NSDictionary *attributeDict;
@property (atomic, readonly, strong) NSString *content;

- (id)initWithXMLData:(NSData *)data;

@end
