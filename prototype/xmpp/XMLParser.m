//
//  XMLParser.m
//  xmpp
//
//  Created by Martin Ott on Wed Sep 17 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import "XMLParser.h"

@interface XMLParser (XMLParserPrivateAdditions)

- (BOOL)parsingCDATA;
- (void)setParsingCDATA:(BOOL)state;
- (NSMutableData *)CDATA;
- (void)setCDATA:(NSMutableData *)data;

@end

#pragma mark -

@implementation XMLParser (XMLParserPrivateAdditions)

- (BOOL)parsingCDATA
{
    return I_parsingCDATA;
}

- (void)setParsingCDATA:(BOOL)state
{
    I_parsingCDATA = state;
}

- (NSMutableData *)CDATA
{
    return I_CDATA;
}

- (void)setCDATA:(NSMutableData *)data
{
    [I_CDATA autorelease];
    I_CDATA = [data mutableCopy];
}

@end

#pragma mark -

int getElementAndNamespaceFromUTF8String(const XML_Char *string,NSString **element, NSString **namespace)
{
    NSString *nameString=[[NSString alloc] initWithUTF8String:string];
    NSArray  *elementAndNamespace = [nameString componentsSeparatedByString:@"|"];
    *element = @"";
    *namespace = @"";
    if ([elementAndNamespace count] == 1) {
       *element=[elementAndNamespace objectAtIndex:0];
    }
    if ([elementAndNamespace count] > 1) {
       *namespace = [elementAndNamespace objectAtIndex:0];
       *element = [elementAndNamespace objectAtIndex:1];
    }
    [nameString release];
    return [elementAndNamespace count];
}

static void StartElementHandler(void *userData, const XML_Char *name, const XML_Char **attributes) 
{
    XMLParser *parser = (XMLParser *)userData;
    id delegate = [parser delegate];
    if ([delegate respondsToSelector:@selector(streamParser:didStartElement:namespaceURI:attributes:)]) {
        NSString *element,*namespaceURI;
        getElementAndNamespaceFromUTF8String(name, &element, &namespaceURI);
        
        NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
        int loop = 0;
        for (loop = 0; attributes[loop]; loop += 2) {
            [attributeDictionary setValue:[NSString stringWithUTF8String:attributes[loop + 1]]
                                   forKey:[NSString stringWithUTF8String:attributes[loop]]];
        }
        [delegate streamParser:parser didStartElement:element 
                  namespaceURI:namespaceURI attributes:attributeDictionary]; 
    }
}

static void EndElementHandler(void *userData, const XML_Char *name)
{
    XMLParser *parser=(XMLParser *)userData;
    id delegate = [parser delegate];
    if ([delegate respondsToSelector:@selector(streamParser:didEndElement:namespaceURI:)]) {
        NSString *element,*namespaceURI;
        getElementAndNamespaceFromUTF8String(name, &element, &namespaceURI);
        [delegate streamParser:parser didEndElement:element namespaceURI:namespaceURI];
    }
}

static void StartNamespaceDeclarationHandler(void *userData,const XML_Char *prefix,const XML_Char *uri)
{
    XMLParser *parser = (XMLParser *)userData;
    id delegate = [parser delegate];
    if ([delegate respondsToSelector:@selector(streamParser:didStartMappingPrefix:toURI:)]) {
        NSString *prefixString = @"";
        if (prefix != nil) {
            prefixString = [NSString stringWithUTF8String:prefix];
        }
        NSString *uriString = @"";
        if (uri != nil) {
            uriString = [NSString stringWithUTF8String:uri];
        }
        [delegate streamParser:parser didStartMappingPrefix:prefixString toURI:uriString];
    }
}

static void EndNamespaceDeclarationHandler(void *userData,const XML_Char *prefix)
{
    XMLParser *parser = (XMLParser *)userData;
    id delegate = [parser delegate];
    if ([delegate respondsToSelector:@selector(streamParser:didEndMappingPrefix:)]) {
        NSString *prefixString = @"";
        if (prefix != nil) {
            prefixString = [NSString stringWithUTF8String:prefix];
        }
        [delegate streamParser:parser didEndMappingPrefix:prefixString];
    }
}

static void CharacterHandler(void *userData, const XML_Char *s, int len)
{
    XMLParser *parser = (XMLParser *)userData;
    id delegate = [parser delegate];
    if ([parser parsingCDATA]) {
        [[parser CDATA] appendBytes:s length:len];
    } else {
        if ([delegate respondsToSelector:@selector(streamParser:foundCharacters:)]) {
            NSString *characters = @"";
            if (s != nil) {
                characters = [[[NSString alloc]initWithBytes:s length:len encoding:NSUTF8StringEncoding] autorelease];
            }
            [delegate streamParser:parser foundCharacters:characters];
        }
    }
} 

static void StartCdataSectionHandler(void *userData)
{
    XMLParser *parser = (XMLParser *)userData;
    [parser setParsingCDATA:YES];
    [parser setCDATA:[NSMutableData new]];
}

static void EndCdataSectionHandler(void *userData)
{
    XMLParser *parser = (XMLParser *)userData;
    id delegate = [parser delegate];
    [parser setParsingCDATA:NO];
    if ([delegate respondsToSelector:@selector(streamParser:foundCDATA:)]) {
        [delegate streamParser:parser foundCDATA:[[parser CDATA] autorelease]];
    }
}

static void CommentHandler(void *userData, const XML_Char *data)
{
    XMLParser *parser = (XMLParser *)userData;
    id delegate = [parser delegate];
    if ([delegate respondsToSelector:@selector(streamParser:foundComment:)]) {
        NSString *comment = @"";
        if (data != nil) {
            comment = [NSString stringWithUTF8String:data];
        }
        [delegate streamParser:parser foundComment:comment];
    }
}

static void ProcessingInstructionHandler(void *userData, const XML_Char *target, const XML_Char *data)
{
    XMLParser *parser = (XMLParser *)userData;
    id delegate = [parser delegate];
    if ([delegate respondsToSelector:@selector(streamParser:foundProcessingInstructionWithTarget:data:)]) {
        NSString *targetString = @"";
        if (target != nil) {
            targetString = [NSString stringWithUTF8String:target];
        }
        NSString *dataString = @"";
        if (data != nil) {
            dataString = [NSString stringWithUTF8String:data];
        }
        [delegate streamParser:parser foundProcessingInstructionWithTarget:targetString data:dataString];
    }
}

#pragma mark -

@implementation XMLParser


+ (XMLParser *)XMLParser
{
    XMLParser *parser = [XMLParser new];
    return [parser autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
        I_expatParser = XML_ParserCreateNS(nil,(XML_Char) '|');
        XML_SetUserData(I_expatParser,(void *)self);
        XML_SetElementHandler(I_expatParser,
            StartElementHandler, EndElementHandler);
        XML_SetNamespaceDeclHandler(I_expatParser,
            StartNamespaceDeclarationHandler,EndNamespaceDeclarationHandler);
        XML_SetCharacterDataHandler(I_expatParser, CharacterHandler);
        XML_SetCdataSectionHandler(I_expatParser, StartCdataSectionHandler,
            EndCdataSectionHandler);
        XML_SetCommentHandler(I_expatParser, CommentHandler);
        XML_SetProcessingInstructionHandler(I_expatParser, ProcessingInstructionHandler);
        
        I_parsingCDATA = NO;
    } 
    return self;
}

- (void)dealloc
{
    XML_ParserFree(I_expatParser);
    [I_CDATA release];
    [super dealloc];
}


- (void)setDelegate:(id)aDelegate
{
    I_delegate = aDelegate;
}

- (id)delegate
{
    return I_delegate;
}


- (BOOL)parseData:(NSData *)aData moreComing:(BOOL)moreComing
{
    // int XML_Parse(XML_Parser p, const char *s, int len, int isFinal)
    int error = XML_Parse(I_expatParser, [aData bytes], [aData length], !moreComing);
    if (error == XML_STATUS_ERROR) {
        if ([I_delegate respondsToSelector:@selector(streamParser:didFailWithReason:)]) {
            [I_delegate streamParser:self didFailWithReason:[self errorString]];
        }
    }
    return (error == XML_STATUS_OK);
}

- (int)errorCode
{
    return XML_GetErrorCode(I_expatParser);
}

- (NSString *)errorString
{
    return [NSString stringWithUTF8String:XML_ErrorString([self errorCode])];
}

- (int)columnNumber
{
    return XML_GetCurrentColumnNumber(I_expatParser);
}

- (int)lineNumber
{
    return XML_GetCurrentLineNumber(I_expatParser);
}

@end
