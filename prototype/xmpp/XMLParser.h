//
//  XMLParser.h
//  xmpp
//
//  Created by Martin Ott on Wed Sep 17 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//
//  expat reference: http://www.xml.com/lpt/a/1999/09/expat/reference.html
//  expat tutorial:  http://www.xml.com/lpt/a/1999/09/expat/index.html

#import <Foundation/Foundation.h>
#import "expat.h"

@interface XMLParser : NSObject {
@private
    XML_Parser I_expatParser;
    id I_delegate;
    BOOL I_parsingCDATA;
    NSMutableData *I_CDATA;
}

+ (XMLParser *)XMLParser;

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


@interface NSObject (XMLParserDelegate)

- (void)streamParser:(XMLParser *)parser didStartElement:(NSString *)elementName 
        namespaceURI:(NSString *)namespaceURI attributes:(NSDictionary *)attributeDict;
- (void)streamParser:(XMLParser *)parser didEndElement:(NSString *)elementName 
        namespaceURI:(NSString *)namespaceURI;
- (void)streamParser:(XMLParser *)parser didStartMappingPrefix:(NSString *)prefix toURI:(NSString *)namespaceURI;
- (void)streamParser:(XMLParser *)parser didEndMappingPrefix:(NSString *)prefix;
- (void)streamParser:(XMLParser *)parser foundCharacters:(NSString *)string;
- (void)streamParser:(XMLParser *)parser foundCDATA:(NSData *)CDATABlock;
- (void)streamParser:(XMLParser *)parser foundComment:(NSString *)comment;
- (void)streamParser:(XMLParser *)parser foundProcessingInstructionWithTarget:(NSString *)target data:(NSString *)data;
- (void)streamParser:(XMLParser *)parser didFailWithReason:(NSString *)errorString;

@end
