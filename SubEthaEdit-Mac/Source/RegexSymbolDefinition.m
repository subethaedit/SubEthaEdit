//  RegexSymbolDefinition.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on Thu Apr 22 2004.
//  Updated by Michael Ehrmann on Fri Oct 11 2013.

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "RegexSymbolDefinition.h"

static NSString * const SEERegexSymbolDefinitionDomain = @"SEERegexSymbolDefinitionDomain";

static NSString * const XMLElementSymbols = @"symbols";

static NSString * const XMLElementBlocks = @"blocks";
static NSString * const XMLElementBlocksBeginRegex = @"beginregex";
static NSString * const XMLElementBlocksEndRegex = @"endregex";

static NSString * const XMLElementSymbol = @"symbol";
static NSString * const XMLElementSymbolRegex = @"regex";
static NSString * const XMLElementSymbolPostProcess = @"postprocess";
static NSString * const XMLElementSymbolPostProcessFind = @"find";
static NSString * const XMLElementSymbolPostProcessReplace = @"replace";

static NSString * const XMLAttributeID = @"id";
static NSString * const XMLAttributeImage = @"image";
static NSString * const XMLAttributeSymbol = @"symbol";
static NSString * const XMLAttributeIndentation = @"indentation";
static NSString * const XMLAttributeIgnoreBlocks = @"ignoreblocks";
static NSString * const XMLAttributeShowInComments = @"show-in-comments";
static NSString * const XMLAttributeFontWeight = @"font-weight";
static NSString * const XMLAttributeFontStyle = @"font-style";
static NSString * const XMLAttributeFontTrait = @"font-trait";

@interface RegexSymbolDefinition ()

@property (atomic, readwrite, strong) DocumentMode *mode;
@property (atomic, readwrite, strong) OGRegularExpression *block;
@property (atomic, readwrite, copy) NSArray *symbols;
@property (atomic, readwrite, strong) NSError *xmlStructureError;

@property (atomic, readwrite, strong) NSMutableArray *symbolsElementInProgress;
@property (atomic, readwrite, strong) NSMutableDictionary *blockElementInProgress;
@property (atomic, readwrite, strong) NSMutableDictionary *symbolElementInProgress;
@property (atomic, readwrite, strong) NSMutableArray *postProcessElementInProgress;
@property (atomic, readwrite, strong) NSMutableArray *postProcessFindReplaceElementInProgress;

@property (atomic, readwrite, strong) NSMutableString *xmlCharactersInProgress;

- (BOOL)parseXMLFile:(NSString *)aPath error:(NSError **)outError;
- (OGRegularExpression *)blockRegularExpressionWithDictionary:(NSDictionary *)blockDictionary error:(NSError **)outError;
- (OGRegularExpression *)regularExpressionWithString:(NSString *)regExString error:(NSError **)outError;

@end


@implementation RegexSymbolDefinition

/*"Initiates the Syntax Definition with an XML file"*/
- (id)initWithFile:(NSString *)path forMode:(DocumentMode *)mode
{
    self = [super init];
    if (self)
    {
        if (!path)
        {
            return nil;
        }

        self.mode = mode;

		NSError *error = nil;
        if (! [self parseXMLFile:path error:&error])
        {
            NSLog(@"Critical errors while loading symbol definition. Not loading symbol parser. Error: %@", error);
            return nil;
        }
        DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Initiated new SyntaxDefinition:%@", [self description]);
    }
    return self;
}


#pragma mark - XML parsing

/*"Entry point for XML parsing, branches to according node functions"*/
- (BOOL)parseXMLFile:(NSString *)path error:(NSError **)outError
{
    NSURL *sourceURL = [NSURL fileURLWithPath:path];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:sourceURL];

    parser.delegate = self;

	if (! [parser parse])
	{
		NSError *parserError = parser.parserError;

		if (parserError.code != NSXMLParserDelegateAbortedParseError)
		{
			NSLog(@"Error parsing syntax definition \"%@\":\n%@", path, parser.parserError);
			if (outError)
			{
				*outError = parser.parserError;
			}
		}
		else
		{
			NSLog(@"Error parsing syntax definition \"%@\":\n%@", path, self.xmlStructureError);
			if (outError)
			{
				*outError = self.xmlStructureError;
			}
		}
		return NO;
	}
	return YES;
}

- (OGRegularExpression *)blockRegularExpressionWithDictionary:(NSDictionary *)blockDictionary error:(NSError **)outError
{
	OGRegularExpression *resultRegEx = nil;
	NSString *blockBegin = blockDictionary[XMLElementBlocksBeginRegex];
	NSString *blockEnd   = blockDictionary[XMLElementBlocksEndRegex];
	if (blockBegin && blockEnd)
	{
		NSString *combined = [NSString stringWithFormat:@"(%@(?!%@))|(%@)", blockBegin, blockEnd, blockBegin];
		if ([OGRegularExpression isValidExpressionString:combined])
		{
			resultRegEx = [[OGRegularExpression alloc] initWithString:combined options:OgreFindNotEmptyOption];
		}
		else
		{
			NSDictionary *errorUserInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Regular Expression Error", @"Regular Expression Error Title"),
											NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"One of the specified <block> elements is not a valid regular expression. Therefore the combined start regex \"%@\" could not be compiled. Please check your regular expression in Find Panel's Ruby mode.", @"Symbol Regular Expression Error Informative Text"), combined]};

			NSError *error = [NSError errorWithDomain:SEERegexSymbolDefinitionDomain code:1 userInfo:errorUserInfo];
			if (outError)
			{
				*outError = error;
			}
			else
			{
				NSLog(@"ERROR: %@ is not a valid Regex.\n%@", combined, error);
			}
		}
	}
	return resultRegEx;
}


- (OGRegularExpression *)regularExpressionWithString:(NSString *)regExString error:(NSError **)outError
{
	OGRegularExpression *resultRegEx = nil;
	if ([OGRegularExpression isValidExpressionString:regExString])
	{
		resultRegEx = [[OGRegularExpression alloc] initWithString:regExString options:OgreFindNotEmptyOption];
	}
	else
	{
		NSDictionary *errorUserInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Regular Expression Error", @"Regular Expression Error Title"),
										NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"\"%@\" is not a valid regular expression. Please check your regular expression in Find Panel's Ruby mode.", @"Symbol Regular Expression Error Informative Text"), regExString]};

		NSError *error = [NSError errorWithDomain:SEERegexSymbolDefinitionDomain code:2 userInfo:errorUserInfo];
		if (outError)
		{
			*outError = error;
		}
		else
		{
			NSLog(@"ERROR: %@ is not a valid Regex.\n%@", regExString, error);
		}
	}
	return resultRegEx;
}


#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if([elementName isEqualToString:XMLElementSymbols])
	{
		self.symbolsElementInProgress = [NSMutableArray array];
	}
	else if ([elementName isEqualToString:XMLElementBlocks])
	{
		self.blockElementInProgress = [NSMutableDictionary dictionaryWithCapacity:2];
	}
	else if ([elementName isEqualToString:XMLElementSymbol])
	{
		NSMutableDictionary *symbolDict = [NSMutableDictionary dictionary];

		if ([attributeDict objectForKey:XMLAttributeSymbol]) {
			NSString *symbolName = [attributeDict objectForKey:XMLAttributeSymbol];
			NSImage *image = [NSImage symbolImageNamed:symbolName];
			if (image) {
				[symbolDict setObject:image forKey:XMLAttributeImage];
			}
		}
		
		if ([attributeDict objectForKey:XMLAttributeImage])
		{
			NSString *imageName = [attributeDict objectForKey:XMLAttributeImage];

			NSBundle *modeBundle = [[self mode] bundle];
			NSImage *image = [modeBundle imageForResource:imageName];
			if (!image) image = [NSImage imageNamed:imageName];
			if (image)
			{
				[symbolDict setObject:image forKey:XMLAttributeImage];
			}
			else
			{
				NSLog(@"Can't find image '%@'", imageName);
			}
		}

		if ([attributeDict objectForKey:XMLAttributeID]) [symbolDict setObject:[attributeDict objectForKey:XMLAttributeID] forKey:XMLAttributeID];
		if ([attributeDict objectForKey:XMLAttributeIndentation]) [symbolDict setObject:[attributeDict objectForKey:XMLAttributeIndentation] forKey:XMLAttributeIndentation];
		if ([attributeDict objectForKey:XMLAttributeIgnoreBlocks]) [symbolDict setObject:[attributeDict objectForKey:XMLAttributeIgnoreBlocks] forKey:XMLAttributeIgnoreBlocks];
		if ([attributeDict objectForKey:XMLAttributeShowInComments]) [symbolDict setObject:[attributeDict objectForKey:XMLAttributeShowInComments] forKey:XMLAttributeShowInComments];
		if ([attributeDict objectForKey:XMLAttributeFontWeight] || [attributeDict objectForKey:XMLAttributeFontStyle])
		{
			NSFontTraitMask mask = 0;
			if ([[attributeDict objectForKey:XMLAttributeFontWeight] isEqualTo:@"bold"]) mask = mask | NSBoldFontMask;
			if ([[attributeDict objectForKey:XMLAttributeFontStyle] isEqualTo:@"italic"]) mask = mask | NSItalicFontMask;
			[symbolDict setObject:@(mask) forKey:XMLAttributeFontTrait];
		}
		self.symbolElementInProgress = symbolDict;
	}
	else if ([elementName isEqualToString:XMLElementSymbolPostProcess])
	{
		self.postProcessElementInProgress = [NSMutableArray array];
	}
	else if ([elementName isEqualToString:XMLElementSymbolPostProcessFind])
	{
		self.postProcessFindReplaceElementInProgress = [NSMutableArray arrayWithCapacity:2];
	}
	self.xmlCharactersInProgress = nil;
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	// symbols element
	if([elementName isEqualToString:XMLElementSymbols])
	{
		self.symbols = self.symbolsElementInProgress;
		self.symbolsElementInProgress = nil;
	}

	// blocks element
	else if ([elementName isEqualToString:XMLElementBlocks])
	{
		NSError *error = nil;
		OGRegularExpression *blockRegEx = [self blockRegularExpressionWithDictionary:self.blockElementInProgress error:&error];
		self.xmlStructureError = error;
		if (! error)
			self.block = blockRegEx;

		self.blockElementInProgress = nil;
	}
	else if ([elementName isEqualToString:XMLElementBlocksBeginRegex])
	{
		if (self.xmlCharactersInProgress)
		{
			self.blockElementInProgress[XMLElementBlocksBeginRegex] = self.xmlCharactersInProgress;
		}
	}
	else if ([elementName isEqualToString:XMLElementBlocksEndRegex])
	{
		if (self.xmlCharactersInProgress)
		{
			self.blockElementInProgress[XMLElementBlocksEndRegex] = self.xmlCharactersInProgress;
		}
	}

	// symbol element
	else if ([elementName isEqualToString:XMLElementSymbol])
	{
		[self.symbolsElementInProgress addObject:self.symbolElementInProgress];
		self.symbolElementInProgress = nil;
	}
	else if ([elementName isEqualToString:XMLElementSymbolRegex])
	{
		NSError *error = nil;
		OGRegularExpression *regEx = [self regularExpressionWithString:self.xmlCharactersInProgress error:&error];
		self.xmlStructureError = error;
		if (! error && regEx)
			self.symbolElementInProgress[XMLElementSymbolRegex] = regEx;
	}
	else if ([elementName isEqualToString:XMLElementSymbolPostProcess])
	{
		self.symbolElementInProgress[XMLElementSymbolPostProcess] = self.postProcessElementInProgress;
		self.postProcessElementInProgress = nil;
	}
	else if ([elementName isEqualToString:XMLElementSymbolPostProcessFind])
	{
		NSError *error = nil;
		OGRegularExpression *regEx = [self regularExpressionWithString:self.xmlCharactersInProgress error:&error];
		self.xmlStructureError = error;
		if (! error && regEx)
			[self.postProcessFindReplaceElementInProgress addObject:regEx];
	}
	else if ([elementName isEqualToString:XMLElementSymbolPostProcessReplace])
	{
		if (self.postProcessFindReplaceElementInProgress.count == 1) // make sure we have a find item before adding a replace string
		{
			[self.postProcessFindReplaceElementInProgress addObject:self.xmlCharactersInProgress?self.xmlCharactersInProgress:@""];
			[self.postProcessElementInProgress addObject:self.postProcessFindReplaceElementInProgress];
		}
		else
		{
			NSDictionary *errorUserInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"XML Structure wrong", @"XML structural error title"),
											NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Find regEx is missing.", @"Symbol Regular Expression Error Informative Text")};

			NSError *error = [NSError errorWithDomain:SEERegexSymbolDefinitionDomain code:3 userInfo:errorUserInfo];
			self.xmlStructureError = error;
		}
		self.postProcessFindReplaceElementInProgress = nil;
	}

	self.xmlCharactersInProgress = nil;

	if (self.xmlStructureError)
	{
		[parser abortParsing];
	}
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
