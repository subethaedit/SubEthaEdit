//
//  SEPDocument.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 09.04.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import "SEPDocument.h"
#import "SEPLogger.h"
#import "SyntaxHighlighter.h"
#import "DocumentModeManager.h"
#import "PreferenceKeys.h"
#import "FoldableTextStorage.h"
#import "FullTextStorage.h"


@implementation SEPDocument

@synthesize textStorage;

- (id)initWithURL:(NSURL *)inURL
{
	if ((self = [super init])) {
		NSDictionary *documentAttributes = nil;
		NSError *error = nil;
		self.textStorage = [NSTextStorage new];
		if ([textStorage readFromURL:inURL options:[NSDictionary dictionaryWithObjectsAndKeys:NSPlainTextDocumentType,@"DocumentType",nil] documentAttributes:&documentAttributes error:&error]) {
			[self setPlainFont:[NSFont systemFontOfSize:12]];
//			[SEPLogger logWithFormat:@"%s Attributes:%@", __FUNCTION__, documentAttributes];
			I_documentMode = [[DocumentModeManager sharedInstance] documentModeForPath:[inURL path] withContentString:[textStorage string]];
		} else {
			[SEPLogger logWithFormat:@"%s loading failed with error:%@", __FUNCTION__, error];
			self.textStorage = nil;
			[self release];
			self = nil;
		}
	}
	
	return self;
}


- (void)changeToFoldableTextStorage {
	id foldableTextStorage = [FoldableTextStorage new];
	[[foldableTextStorage mutableString] setString:[textStorage string]];
	self.textStorage = foldableTextStorage;
}

- (void)addOneFolding {
	// just fold the last character to create the second textstorage
	[textStorage foldRange:NSMakeRange([textStorage length]-1,1)];
}


- (void)foldEveryOtherLine {
	NSString *string = [textStorage string];
	NSRange lineRange = NSMakeRange([string length]-1,1);
	
	int counter = 0;
	while (lineRange.location > 0) {
		lineRange = [string lineRangeForRange:NSMakeRange(lineRange.location-1,1)];
		counter++;
		if (counter % 2) {
			[textStorage foldRange:lineRange];
		}
	}
}

- (NSTimeInterval)timedHighlightAll {
	SyntaxHighlighter *syntaxHighlighter = [I_documentMode syntaxHighlighter];
	if (!syntaxHighlighter) NSLog(@"no higlighter");
	id textStorageToHighlight = textStorage;
	if ([textStorageToHighlight isKindOfClass:[FoldableTextStorage class]]) {
		textStorageToHighlight = [textStorageToHighlight fullTextStorage];
	}
	
	[textStorageToHighlight removeAttribute:kSyntaxHighlightingIsCorrectAttributeName range:NSMakeRange(0,[textStorageToHighlight length])];
	START_TIMING(highlighting);
	int numberOfRuns = 1;
	while (![syntaxHighlighter colorizeDirtyRanges:textStorageToHighlight ofDocument:self]) {
		numberOfRuns++;
	}
	NSTimeInterval result = END_TIMING(highlighting);
	NSLog(@"%s %d number of calls into the highlighter",__FUNCTION__,numberOfRuns);
	return result;
}

- (DocumentMode *)documentMode {
	return I_documentMode;
}

- (void)dealloc {
	[textStorage release];
	[super dealloc];
}

- (void)TCM_styleFonts {
    [I_fonts.boldFont autorelease];
    [I_fonts.italicFont autorelease];
    [I_fonts.boldItalicFont autorelease];
    NSFontManager *manager=[NSFontManager sharedFontManager];
    I_fonts.boldFont       = [[manager convertFont:I_fonts.plainFont toHaveTrait:NSBoldFontMask] retain];
    I_fonts.italicFont     = [[manager convertFont:I_fonts.plainFont toHaveTrait:NSItalicFontMask] retain];
    I_fonts.boldItalicFont = [[manager convertFont:I_fonts.boldFont  toHaveTrait:NSItalicFontMask] retain];
}

- (void)setPlainFont:(NSFont *)aFont {
    [I_styleCacheDictionary autorelease];
    I_styleCacheDictionary = [NSMutableDictionary new];
//    BOOL useDefaultStyle=[[[self documentMode] defaultForKey:DocumentModeUseDefaultStylePreferenceKey] boolValue];
//    BOOL darkBackground=[[[self documentMode] defaultForKey:DocumentModeBackgroundColorIsDarkPreferenceKey] boolValue];
//    NSDictionary *syntaxStyle=[useDefaultStyle?[[DocumentModeManager baseMode] syntaxStyle]:[[self documentMode] syntaxStyle] styleForKey:SyntaxStyleBaseIdentifier];
//    [self setDocumentBackgroundColor:[syntaxStyle objectForKey:darkBackground?@"inverted-background-color":@"background-color"]];
//    [self setDocumentForegroundColor:[syntaxStyle objectForKey:darkBackground?@"inverted-color":@"color"]];
    [I_fonts.plainFont autorelease];
    I_fonts.plainFont = [aFont copy];
    [self TCM_styleFonts];
}


/*"A font trait mask of 0 returns the plain font, otherwise use NSBoldFontMask, NSItalicFontMask"*/
- (NSFont *)fontWithTrait:(NSFontTraitMask)aFontTrait {
    if ((aFontTrait & NSBoldFontMask) && (aFontTrait & NSItalicFontMask)) {
        return I_fonts.boldItalicFont;
    } else if (aFontTrait & NSItalicFontMask) {
        return I_fonts.italicFont;
    } else if (aFontTrait & NSBoldFontMask) {
        return I_fonts.boldFont;
    } else {
        return I_fonts.plainFont;
    }
}

- (NSDictionary *)styleAttributesForStyleID:(NSString *)aStyleID {
	if (!aStyleID) {
		NSLog(@"%s was called with a styleID of nil",__FUNCTION__);
		return [NSDictionary dictionary];
	}
    NSDictionary *result=[I_styleCacheDictionary objectForKey:aStyleID];
    if (!result) {
        DocumentMode *documentMode=I_documentMode;
        BOOL darkBackground=[[documentMode defaultForKey:DocumentModeBackgroundColorIsDarkPreferenceKey] boolValue];
        NSDictionary *style=nil;
        if ([aStyleID isEqualToString:SyntaxStyleBaseIdentifier] && 
            [[documentMode defaultForKey:DocumentModeUseDefaultStylePreferenceKey] boolValue]) {
            style=[[[DocumentModeManager baseMode] syntaxStyle] styleForKey:aStyleID];
        } else {
            style=[[documentMode syntaxStyle] styleForKey:aStyleID];
        }
        NSFontTraitMask traits=[[style objectForKey:@"font-trait"] unsignedIntValue];
        NSFont *font=[self fontWithTrait:traits];
        BOOL synthesise=[[NSUserDefaults standardUserDefaults] boolForKey:SynthesiseFontsPreferenceKey];
        float obliquenessFactor=0.;
        if (synthesise && (traits & NSItalicFontMask) && !([[NSFontManager sharedFontManager] traitsOfFont:font] & NSItalicFontMask)) {
            obliquenessFactor=.2;
        }
        float strokeWidth=.0;
        if (synthesise && (traits & NSBoldFontMask) && !([[NSFontManager sharedFontManager] traitsOfFont:font] & NSBoldFontMask)) {
            strokeWidth=darkBackground?-9.:-3.;
        }
        NSColor *foregroundColor=[style objectForKey:darkBackground?@"inverted-color":@"color"];
        result=[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,
            foregroundColor,NSForegroundColorAttributeName,
            aStyleID,@"styleID",
            [NSNumber numberWithFloat:obliquenessFactor],NSObliquenessAttributeName,
            [NSNumber numberWithFloat:strokeWidth],NSStrokeWidthAttributeName,
            nil];
        [I_styleCacheDictionary setObject:result forKey:aStyleID];
    }
    return result;
}


@end
