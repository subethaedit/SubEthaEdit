//  TCMBEEPSessionXMLParser.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 14.10.13.


#import "TCMBEEPSessionXMLParser.h"

NSString * const TCMBEEPSessionXMLElementReady = @"ready";
NSString * const TCMBEEPSessionXMLElementProceed = @"proceed";
NSString * const TCMBEEPSessionXMLElementError = @"error";

NSString * const TCMBEEPSessionXMLAttributeVersion = @"version";
NSString * const TCMBEEPSessionXMLAttributeCode = @"code";

@interface TCMBEEPSessionXMLParser ()

@property (atomic, readwrite, strong) NSString *elementName;
@property (atomic, readwrite, strong) NSDictionary *attributeDict;
@property (atomic, readwrite, strong) NSString *content;

@property (atomic, readwrite, strong) NSMutableString *xmlCharactersInProgress;

@end


@implementation TCMBEEPSessionXMLParser

- (instancetype)initWithXMLData:(NSData *)data
{
    self = [super init];
    if (self) {
		if (! data)
		{
			return nil;
		}

		NSError * error = nil;
		if (! [self parseData:data error:&error])
		{
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
	if (error)
	{
		if (outError)
		{
			*outError = error;
		}
		return NO;
	}

	return YES;
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if (self.elementName)
	{
		NSLog(@"Second element (%@) in BEEPSession XML response. structure invalid, aborting... (First element: %@)", elementName, self.elementName);
		[parser abortParsing];
		return;
	}
	
	self.elementName = elementName;
	self.attributeDict = attributeDict;
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if ([elementName isEqualToString:self.elementName])
	{
		self.content = self.xmlCharactersInProgress;
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


- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	NSLog(@"parseErrorOccurred: %@", parseError);
}


- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError
{
	NSLog(@"validationErrorOccurred: %@", validationError);
}


@end
