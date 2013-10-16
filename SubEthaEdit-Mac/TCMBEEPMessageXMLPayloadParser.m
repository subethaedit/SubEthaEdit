//
//  TCMBEEPMessageXMLPayloadParser.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 14.10.13.
//  Copyright (c) 2013 TheCodingMonkeys. All rights reserved.
//

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif


NSString * const TCMBEEPMessageXMLElementGreeting = @"greeting";
NSString * const TCMBEEPMessageXMLElementStart = @"start";
NSString * const TCMBEEPMessageXMLElementClose = @"close";
NSString * const TCMBEEPMessageXMLElementProfile = @"profile";
NSString * const TCMBEEPMessageXMLElementOkay = @"ok";
NSString * const TCMBEEPMessageXMLElementError = @"error";

NSString * const TCMBEEPMessageXMLAttributeFeatures = @"features";
NSString * const TCMBEEPMessageXMLAttributeLocalize = @"localize";
NSString * const TCMBEEPMessageXMLAttributeURI = @"uri";
NSString * const TCMBEEPMessageXMLAttributeChannelNumber = @"number";
NSString * const TCMBEEPMessageXMLAttributeCode = @"code";

#import "TCMBEEPMessageXMLPayloadParser.h"

@interface TCMBEEPMessageXMLPayloadParser ()

@property (atomic, readwrite, copy) NSString *messageType;
@property (atomic, readwrite, copy) NSDictionary *messageAttributeDict;
@property (atomic, readwrite, copy) NSData *messageData;
@property (atomic, readwrite, copy) NSArray *profileURIs;
@property (atomic, readwrite, copy) NSArray *profileDataBlocks;

@property (atomic, readwrite, strong) NSMutableArray *profileURIsInProgress;
@property (atomic, readwrite, strong) NSData *profileDataBlockInProgress;
@property (atomic, readwrite, strong) NSMutableArray *profileDataBlocksInProgress;

@property (atomic, readwrite, strong) NSMutableString *xmlCharactersInProgress;

@end


@implementation TCMBEEPMessageXMLPayloadParser

- (instancetype)initWithXMLData:(NSData *)data
{
    self = [super init];
    if (self) {
		if (! data) {
			return nil;
		}

		NSError * error = nil;
		if (! [self parseData:data error:&error]) {
			NSLog(@"%s - Error parsing XML Data: %@", __PRETTY_FUNCTION__, error);
			return nil;
		}
    }
    return self;
}


- (BOOL)parseData:(NSData *)data error:(NSError **)outError
{
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
	parser.delegate = self;

	[parser parse];

	NSError *error = parser.parserError;
	if (error) {
		if (outError) {
			*outError = error;
		}
		return NO;
	}

	return YES;
}


#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if (! self.messageType) {
		self.messageType = elementName;
	}
	if (! self.messageAttributeDict)
	{
		self.messageAttributeDict = attributeDict;
	}

	if ([elementName isEqualToString:TCMBEEPMessageXMLElementGreeting]) {
		DEBUGLOG(@"BEEPLogDomain", DetailedLogLevel, @"Was greeting....");
		self.profileURIsInProgress = [NSMutableArray array];
	}
	else if ([elementName isEqualToString:TCMBEEPMessageXMLElementStart])
	{
		self.profileURIsInProgress = [NSMutableArray array];
		self.profileDataBlocksInProgress = [NSMutableArray array];
	}
	else if ([elementName isEqualToString:TCMBEEPMessageXMLElementProfile]) {
		NSString *URI = [attributeDict objectForKey:TCMBEEPMessageXMLAttributeURI];
		if (URI) {
			[self.profileURIsInProgress addObject:URI];
		}
	} else if ([elementName isEqualToString:TCMBEEPMessageXMLElementClose]) {

	}
	else if ([elementName isEqualToString:TCMBEEPMessageXMLElementOkay]) {

	}
	else if ([elementName isEqualToString:TCMBEEPMessageXMLElementError]) {

	}
	else {
		DEBUGLOG(@"BEEPLogDomain", AlwaysLogLevel, @"Unknown element (%@) in BEEPMessage XML. Structure invalid, aborting...", elementName);
	}
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if ([elementName isEqualToString:TCMBEEPMessageXMLElementGreeting]) {
		self.profileURIs = self.profileURIsInProgress;
		self.profileURIsInProgress = nil;
		self.profileDataBlocksInProgress = nil;
	}
	else if ([elementName isEqualToString:TCMBEEPMessageXMLElementStart]) {
		self.profileURIsInProgress = nil;
		self.profileDataBlocksInProgress = nil;
	}
	else if ([elementName isEqualToString:TCMBEEPMessageXMLElementProfile]) {
		if (self.profileDataBlockInProgress) {
			if (self.profileDataBlocksInProgress) {
				[self.profileDataBlocksInProgress addObject:self.profileDataBlockInProgress];
			} else {
				self.messageData = self.profileDataBlockInProgress;
			}
			self.profileDataBlockInProgress = nil;
		}
	}
	else if ([elementName isEqualToString:TCMBEEPMessageXMLElementClose]) {

	}
	else if ([elementName isEqualToString:TCMBEEPMessageXMLElementOkay]) {

	}
	else if ([elementName isEqualToString:TCMBEEPMessageXMLElementError]) {

	}
	self.xmlCharactersInProgress = nil;
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if (! self.xmlCharactersInProgress)
	{
		self.xmlCharactersInProgress = [NSMutableString stringWithString:string];
	}
	else
	{
		[self.xmlCharactersInProgress appendString:string];
	}
}


- (void)parser:(NSXMLParser *)parser foundIgnorableWhitespace:(NSString *)whitespaceString
{
	if (! self.xmlCharactersInProgress)
	{
		self.xmlCharactersInProgress = [NSMutableString stringWithString:whitespaceString];
	}
	else
	{
		[self.xmlCharactersInProgress appendString:whitespaceString];
	}
}


- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock
{
	self.profileDataBlockInProgress = CDATABlock;
}


- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	NSLog(@"parseErrorOccurred: %@", parseError);
}


- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError
{
	NSLog(@"validationErrorOccurred: %@", validationError);
}
@end
