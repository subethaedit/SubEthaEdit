//
//  ParserDelegate.m
//  TCMXMLParser
//
//  Created by Martin Ott on Thu Sep 18 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import "ParserDelegate.h"
#import "TCMXMLParser.h"

@implementation ParserDelegate

- (void)parser:(TCMXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI attributes:(NSDictionary *)attributeDict
{
    NSLog(@"parser:%@ didStartElement:%@ namespaceURI:%@ attributes:%@", parser, elementName, namespaceURI, attributeDict);
}

- (void)parser:(TCMXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI
{
    NSLog(@"parser:%@ didEndElement:%@ namespaceURI:%@", parser, elementName, namespaceURI);
}

- (void)parser:(TCMXMLParser *)parser didStartMappingPrefix:(NSString *)prefix toURI:(NSString *)namespaceURI
{
    NSLog(@"parser:%@ didStartMappingPrefix:%@ toURI:%@", parser, prefix, namespaceURI);
}

- (void)parser:(TCMXMLParser *)parser didEndMappingPrefix:(NSString *)prefix
{
    NSLog(@"parser:%@ didEndMappingPrefix:%@", parser, prefix);
}

- (void)parser:(TCMXMLParser *)parser foundCharacters:(NSString *)string
{
    NSLog(@"parser:%@ foundCharacters:%@", parser, string);
}

- (void)parser:(TCMXMLParser *)parser foundCDATA:(NSData *)CDATABlock
{
    NSLog(@"parser:%@ foundCDATA:%@", parser, CDATABlock);
}

- (void)parser:(TCMXMLParser *)parser foundComment:(NSString *)comment
{
    NSLog(@"parser:%@ foundComment:%@", parser, comment);
}

- (void)parser:(TCMXMLParser *)parser foundProcessingInstructionWithTarget:(NSString *)target data:(NSString *)data
{
    NSLog(@"parser:%@ foundProcessingInstructionWithTarget:%@ data:%@", parser, target, data);
}

- (void)parser:(TCMXMLParser *)parser didFailWithReason:(NSString *)errorString
{
    NSLog(@"parser:%@ didFailWithReason:%@", parser, errorString);
}

@end
