//
//  TCMXLMParser.m
//  TCMXMLParser
//
//  Created by Dominik Wagner on Wed Sep 17 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import "TCMXMLParser.h"


#pragma mark ### Handler functions ###
int getElementAndNamespaceFromUTF8String(XML_Char *string,NSString **element, NSString **namespace) {
    NSString *nameString=[[NSString alloc] initWithUTF8String:string];
    NSArray  *elementAndNamespace=[nameString componentsSeparatedByString:@"|"];
    *element  =@"";
    *namespace=@"";
    if ([elementAndNamespace count]>0) {
       *element=[elementAndNamespace objectAtIndex:0];
    }
    if ([elementAndNamespace count]>1) {
       *namespace=[elementAndNamespace objectAtIndex:1];
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
        int loop=0;
        for (loop=0;attributes[loop];loop+=2) {
            [attributeDictionary setValue:[NSString stringWithUTF8String:attributes[loop  ]]
                                   forKey:[NSString stringWithUTF8String:attributes[loop+1]] ];
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
    
}

static void EndNamespaceDeclarationHandler(void *userData,const XML_Char *prefix)
{

}

static void CharacterHandler(void *userData, const XML_Char *s, int len)
{

} 

static void StartCdataSectionHandler(void *userData)
{
}

static void EndCdataSectionHandler(void *userData)
{
}

static void CommentHandler(void *userData, const XML_Char *data)
{
}

static void ProcessingInstructionHandler(void *userData, const XML_Char *target, const XML_Char *data)
{
}

                                   

@implementation TCMXMLParser

#pragma mark ### Initializers, etc. ###
- (id)init {
    self=[super init];
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
    } 
    return self;
}

- (void)dealloc {
    XML_ParserFree(CM_expatParser);
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
