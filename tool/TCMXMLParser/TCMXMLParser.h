//
//  TCMXMLParser.h
//  TCMXMLParser
//
//  Created by Dominik Wagner on Wed Sep 17 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//
//  expat reference: http://www.xml.com/lpt/a/1999/09/expat/reference.html
//  expat tutorial:  http://www.xml.com/lpt/a/1999/09/expat/index.html

#import <Foundation/Foundation.h>
#import "expat.h"
/*!
    @class      TCMXMLParser
    @abstract   A stream oriented XML parser
    @discussion This class provides a XML parser that is able to parse XML Streams, like used in e.g. Jabber/XMPP.
*/

@interface TCMXMLParser : NSObject {
@private
    XML_Parser CM_expatParser;
    id         CM_delegate;
    BOOL       CM_parsingCDATA;
    NSMutableData *CM_CDATA;
}

+ (TCMXMLParser *)XMLParser;

- (id)init;

- (void)setDelegate:(id)aDelegate;
- (id)delegate;

// returns YES if everything is fine, NO if error occurs
- (BOOL)parseData:(NSData *)aData moreComing:(BOOL)moreComing;

- (int)errorCode;
- (NSString *)errorString;
- (int)columnNumber;
- (int)lineNumber;

@end

@interface NSObject (TCMXMLParserDelegate)

- (void)parser:(TCMXMLParser *)parser didStartElement:(NSString *)elementName 
        namespaceURI:(NSString *)namespaceURI attributes:(NSDictionary *)attributeDict;
- (void)parser:(TCMXMLParser *)parser didEndElement:(NSString *)elementName 
        namespaceURI:(NSString *)namespaceURI;
- (void)parser:(TCMXMLParser *)parser didStartMappingPrefix:(NSString *)prefix toURI:(NSString *)namespaceURI;
- (void)parser:(TCMXMLParser *)parser didEndMappingPrefix:(NSString *)prefix;
- (void)parser:(TCMXMLParser *)parser foundCharacters:(NSString *)string;
- (void)parser:(TCMXMLParser *)parser foundCDATA:(NSData *)CDATABlock;
- (void)parser:(TCMXMLParser *)parser foundComment:(NSString *)comment;
- (void)parser:(TCMXMLParser *)parser foundProcessingInstructionWithTarget:(NSString *)target data:(NSString *)data;
- (void)parser:(TCMXMLParser *)parser didFailWithReason:(NSString *)errorString;
@end
