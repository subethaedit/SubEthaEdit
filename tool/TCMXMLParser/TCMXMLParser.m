//
//  TCMXLMParser.m
//  TCMXMLParser
//
//  Created by Dominik Wagner on Wed Sep 17 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import "TCMXMLParser.h"

@interface TCMXMLParser (TCMXMLParserPrivateAdditions)

- (BOOL)CM_parsingCDATA;
- (void)CM_setParsingCDATA:(BOOL)state;
- (NSMutableData *)CM_CDATA;
- (void)CM_setCDATA:(NSMutableData *)data;

@end

#pragma mark -

@implementation TCMXMLParser (TCMXMLParserPrivateAdditions)

- (BOOL)CM_parsingCDATA
{
    return CM_parsingCDATA;
}

- (void)CM_setParsingCDATA:(BOOL)state
{
    CM_parsingCDATA = state;
}

- (NSMutableData *)CM_CDATA
{
    return CM_CDATA;
}

- (void)CM_setCDATA:(NSMutableData *)data
{
    [CM_CDATA autorelease];
    CM_CDATA = [data mutableCopy];
}

@end

#pragma mark -

int getElementAndNamespaceFromUTF8String(const XML_Char *string,NSString **element, NSString **namespace)
{
    NSString *nameString=[[NSString alloc] initWithUTF8String:string];
    NSArray  *elementAndNamespace=[nameString componentsSeparatedByString:@"|"];
    *element  =@"";
    *namespace=@"";
    if ([elementAndNamespace count] == 1) {
       *element=[elementAndNamespace objectAtIndex:0];
    }
    if ([elementAndNamespace count] > 1) {
       *namespace=[elementAndNamespace objectAtIndex:0];
       *element=[elementAndNamespace objectAtIndex:1];
    }
    [nameString release];
    return [elementAndNamespace count];
}

static void StartElementHandler(void *userData, const XML_Char *name, const XML_Char **attributes) 
{
    TCMXMLParser *parser=(TCMXMLParser *)userData;
    id delegate = [parser delegate];
    if ([delegate respondsToSelector:@selector(parser:didStartElement:namespaceURI:attributes:)]) {
        NSString *element,*namespaceURI;
        getElementAndNamespaceFromUTF8String(name, &element, &namespaceURI);
        
        NSMutableDictionary *attributeDictionary=[NSMutableDictionary dictionary];
        int loop = 0;
        for (loop = 0; attributes[loop]; loop += 2) {
            [attributeDictionary setValue:[NSString stringWithUTF8String:attributes[loop + 1]]
                                   forKey:[NSString stringWithUTF8String:attributes[loop]]];
        }
        [delegate parser:parser didStartElement:element 
                  namespaceURI:namespaceURI attributes:attributeDictionary]; 
    }
}

static void EndElementHandler(void *userData, const XML_Char *name)
{
    TCMXMLParser *parser=(TCMXMLParser *)userData;
    id delegate = [parser delegate];
    if ([delegate respondsToSelector:@selector(parser:didEndElement:namespaceURI:)]) {
        NSString *element,*namespaceURI;
        getElementAndNamespaceFromUTF8String(name, &element, &namespaceURI);
        [delegate parser:parser didEndElement:element namespaceURI:namespaceURI];
    }
}

static void StartNamespaceDeclarationHandler(void *userData,const XML_Char *prefix,const XML_Char *uri)
{
    TCMXMLParser *parser = (TCMXMLParser *)userData;
    id delegate = [parser delegate];
    if ([delegate respondsToSelector:@selector(parser:didStartMappingPrefix:toURI:)]) {
        NSString *prefixString = @"";
        if (prefix != nil) {
            prefixString = [NSString stringWithUTF8String:prefix];
        }
        NSString *uriString = @"";
        if (uri != nil) {
            uriString = [NSString stringWithUTF8String:uri];
        }
        [delegate parser:parser didStartMappingPrefix:prefixString toURI:uriString];
    }
}

static void EndNamespaceDeclarationHandler(void *userData,const XML_Char *prefix)
{
    TCMXMLParser *parser = (TCMXMLParser *)userData;
    id delegate = [parser delegate];
    if ([delegate respondsToSelector:@selector(parser:didEndMappingPrefix:)]) {
        NSString *prefixString = @"";
        if (prefix != nil) {
            prefixString = [NSString stringWithUTF8String:prefix];
        }
        [delegate parser:parser didEndMappingPrefix:prefixString];
    }
}

static void CharacterHandler(void *userData, const XML_Char *s, int len)
{
    TCMXMLParser *parser = (TCMXMLParser *)userData;
    id delegate = [parser delegate];
    if ([parser CM_parsingCDATA]) {
        [[parser CM_CDATA] appendBytes:s length:len];
    } else {
        if ([delegate respondsToSelector:@selector(parser:foundCharacters:)]) {
            NSString *characters = @"";
            if (s != nil) {
                characters = [[[NSString alloc]initWithBytes:s length:len encoding:NSUTF8StringEncoding] autorelease];
            }
            [delegate parser:parser foundCharacters:characters];
        }
    }
} 

static void StartCdataSectionHandler(void *userData)
{
    TCMXMLParser *parser = (TCMXMLParser *)userData;
    [parser CM_setParsingCDATA:YES];
    [parser CM_setCDATA:[NSMutableData new]];
}

static void EndCdataSectionHandler(void *userData)
{
    TCMXMLParser *parser = (TCMXMLParser *)userData;
    id delegate = [parser delegate];
    [parser CM_setParsingCDATA:NO];
    if ([delegate respondsToSelector:@selector(parser:foundCDATA:)]) {
        [delegate parser:parser foundCDATA:[[parser CM_CDATA] autorelease]];
    }
}

static void CommentHandler(void *userData, const XML_Char *data)
{
    TCMXMLParser *parser = (TCMXMLParser *)userData;
    id delegate = [parser delegate];
    if ([delegate respondsToSelector:@selector(parser:foundComment:)]) {
        NSString *comment = @"";
        if (data != nil) {
            comment = [NSString stringWithUTF8String:data];
        }
        [delegate parser:parser foundComment:comment];
    }
}

static void ProcessingInstructionHandler(void *userData, const XML_Char *target, const XML_Char *data)
{
    TCMXMLParser *parser = (TCMXMLParser *)userData;
    id delegate = [parser delegate];
    if ([delegate respondsToSelector:@selector(parser:foundProcessingInstructionWithTarget:data:)]) {
        NSString *targetString = @"";
        if (target != nil) {
            targetString = [NSString stringWithUTF8String:target];
        }
        NSString *dataString = @"";
        if (data != nil) {
            dataString = [NSString stringWithUTF8String:data];
        }
        [delegate parser:parser foundProcessingInstructionWithTarget:targetString data:dataString];
    }
}

#pragma mark -

@implementation TCMXMLParser


+ (TCMXMLParser *)XMLParser
{
    TCMXMLParser *XMLParser = [TCMXMLParser new];
    return [XMLParser autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
        CM_expatParser=XML_ParserCreateNS(nil,(XML_Char) '|');
        XML_SetUserData      (CM_expatParser,(void *)self);
        XML_SetElementHandler(CM_expatParser,
            StartElementHandler,EndElementHandler);
        XML_SetNamespaceDeclHandler(CM_expatParser,
            StartNamespaceDeclarationHandler,EndNamespaceDeclarationHandler);
        XML_SetCharacterDataHandler(CM_expatParser,CharacterHandler);
        XML_SetCdataSectionHandler(CM_expatParser, StartCdataSectionHandler,
            EndCdataSectionHandler);
        XML_SetCommentHandler(CM_expatParser, CommentHandler);
        XML_SetProcessingInstructionHandler(CM_expatParser, ProcessingInstructionHandler);
        
        CM_parsingCDATA = NO;
    } 
    return self;
}

- (void)dealloc
{
    XML_ParserFree(CM_expatParser);
    [CM_CDATA release];
    [super dealloc];
}


- (void)setDelegate:(id)aDelegate
{
    CM_delegate = aDelegate;
}

- (id)delegate
{
    return CM_delegate;
}


- (BOOL)parseData:(NSData *)aData moreComing:(BOOL)moreComing
{
    // int XML_Parse(XML_Parser p, const char *s, int len, int isFinal)
    int error=XML_Parse(CM_expatParser,[aData bytes],[aData length],!moreComing);
    if (error==XML_STATUS_ERROR) {
        if ([CM_delegate respondsToSelector:@selector(parser:didFailWithReason:)]) {
            [CM_delegate parser:self didFailWithReason:[self errorString]];
        }
    }
    return (error==XML_STATUS_OK);
}

- (int)errorCode
{
    return XML_GetErrorCode(CM_expatParser);
}

- (NSString *)errorString
{
    return [NSString stringWithUTF8String:XML_ErrorString([self errorCode])];
}

- (int)columnNumber
{
    return XML_GetCurrentColumnNumber(CM_expatParser);
}

- (int)lineNumber
{
    return XML_GetCurrentLineNumber(CM_expatParser);
}

@end
