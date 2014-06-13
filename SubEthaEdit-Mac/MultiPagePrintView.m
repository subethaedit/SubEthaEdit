//
//  MultiPagePrintView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 25.08.04.
//  Copyright 2004 TheCodingMonkeys. All rights reserved.
//

#import "MultiPagePrintView.h"
#import "FoldableTextStorage.h"
#import "FullTextStorage.h"
#import "PrintTypesetter.h"
#import "PrintTextView.h"
#import "SyntaxHighlighter.h"
#import "DocumentMode.h"
#import "PlainTextDocument.h"
#import "TCMMMUserManager.h"
#import "TCMMMUserSeeAdditions.h"
#import "PlainTextDocument.h"
#import "GeneralPreferences.h"
#import "TCMMMSession.h"
#import "DocumentModeManager.h"

@implementation MultiPagePrintView

static NSMutableDictionary *S_nameAttributes, *S_contactAttributes, *S_contactLabelAttributes, *S_tableHeadingAttributes;

- (id)initWithFrame:(NSRect)frame document:(PlainTextDocument *)aDocument
{
    self = [super initWithFrame:frame];
    
    if (self) {
        I_document = [aDocument retain];

        I_textStorage = [NSTextStorage new];
        [I_textStorage setAttributedString:[(FoldableTextStorage *)[aDocument textStorage] fullTextStorage]];
        
        I_contributorArray = [NSMutableArray new];
        I_visitorArray = [NSMutableArray new];
        I_measures.contributorNameWidth  = 0;
        I_measures.contributorAIMWidth   = 0;
        I_measures.contributorEmailWidth = 0;
        I_measures.visitorNameWidth      = 0;
        I_measures.visitorAIMWidth       = 0;
        I_measures.visitorEmailWidth     = 0;
        I_measures.visitorWidth          = 0;
        I_measures.contributorWidth      = 0;
        I_pagesWithLegend                = 0;
        I_pagesWithFullLegend            = 0;
        
        if (!S_nameAttributes) {
            NSFontManager *fontManager = [NSFontManager sharedFontManager];
            NSFont *font = [NSFont fontWithName:@"Helvetica" size:10.];
            
            if (!font) font = [NSFont systemFontOfSize:10.];
            NSFont *boldFont = [fontManager convertFont:font toHaveTrait:NSBoldFontMask];
            S_nameAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSColor blackColor], NSForegroundColorAttributeName, boldFont, NSFontAttributeName, nil] retain];
            font = [fontManager convertFont:font toSize:8.];
            S_contactAttributes     = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        [NSColor blueColor], NSForegroundColorAttributeName,
                                        font, NSFontAttributeName,
                                        nil] retain];
            S_contactLabelAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         [NSColor grayColor], NSForegroundColorAttributeName,
                                         font, NSFontAttributeName,
                                         nil] retain];
            boldFont = [fontManager convertFont:font toHaveTrait:NSBoldFontMask];
            S_tableHeadingAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         [NSColor blackColor], NSForegroundColorAttributeName,
                                         boldFont, NSFontAttributeName,
                                         nil] retain];
        }
        
        I_measures.emailAIMLabelWidth   = MAX([NSLocalizedString(@"PrintExportLegendEmailLabel", @"Label for Email in legend in Print and Export") sizeWithAttributes:S_contactLabelAttributes].width,
                                              [NSLocalizedString(@"PrintExportLegendAIMLabel", @"Label for AIM in legend in Print and Export") sizeWithAttributes:S_contactLabelAttributes].width);
        
        [self setHeaderFormatString:@"\t%1$@"];
    }
    return self;
}


- (void)dealloc
{
    [I_textStorage removeLayoutManager:I_layoutManager];
    [[[[self subviews] copy] autorelease] makeObjectsPerformSelector:@selector(removeFromSuperviewWithoutNeedingDisplay)];
    [I_document release];
    [I_layoutManager release];
    [I_textStorage release];
    [I_headerAttributes release];
    [I_headerFormatString release];
    [I_contributorArray release];
    [I_visitorArray release];
    [I_baseFont release];
    [I_styleCacheDictionary release];
    [super dealloc];
}


#pragma mark -
#pragma mark ### Accessors ###

- (void)setHeaderFormatString:(NSString *)aString
{
    [I_headerFormatString autorelease];
    I_headerFormatString = [aString copy];
}


- (NSString *)headerFormatString
{
    return I_headerFormatString;
}


- (void)setHeaderAttributes:(NSDictionary *)aHeaderAttributes
{
    [I_headerAttributes autorelease];
    I_headerAttributes = [aHeaderAttributes copy];
}


- (NSDictionary *)headerAttributes
{
    return I_headerAttributes;
}


- (NSString *)printJobTitle
{
    return [I_document displayName];
}


#pragma mark -

#define LEGENDTABLEHEADERHEIGHT 12.
#define LEGENDTABLEENTRYHEIGHT  24.
#define LEGENDIMAGEPADDING      3.

- (NSDictionary *)styleAttributesForStyleID:(NSString *)aStyleID
{
    NSMutableDictionary *result = [I_styleCacheDictionary objectForKey:aStyleID];
    
    if (!result) {
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        DocumentMode *documentMode = [I_document documentMode];
        NSDictionary *style = nil;
        result = [NSMutableDictionary dictionary];
        
        if ([aStyleID isEqualToString:SyntaxStyleBaseIdentifier] &&
            [[documentMode defaultForKey:DocumentModeUseDefaultStylePreferenceKey] boolValue])
        {
            style = [[[DocumentModeManager baseMode] syntaxStyle] styleForKey:aStyleID];
        } else {
            style = [[documentMode syntaxStyle] styleForKey:aStyleID];
        }
        NSFontTraitMask traits = [[style objectForKey:@"font-trait"] unsignedIntValue];
        NSFont *font = I_baseFont;
        
        if (traits & NSItalicFontMask) {
            font = [fontManager convertFont:font toHaveTrait:NSItalicFontMask];
            
            if (!([fontManager traitsOfFont:font] & NSItalicFontMask)) {
                [result setObject:[NSNumber numberWithFloat:.2] forKey:NSObliquenessAttributeName];
            }
        }
        
        if (traits & NSBoldFontMask) {
            font = [fontManager convertFont:font toHaveTrait:NSBoldFontMask];
            
            if (!([fontManager traitsOfFont:font] & NSBoldFontMask)) {
                [result setObject:[NSNumber numberWithFloat:-3.] forKey:NSStrokeWidthAttributeName];
            }
        }
        [result setObject:font forKey:NSFontAttributeName];
        [result setObject:aStyleID forKey:kSyntaxHighlightingStyleIDAttributeName];
        [result setObject:[style objectForKey:@"color"] forKey:NSForegroundColorAttributeName];
        [I_styleCacheDictionary setObject:result forKey:aStyleID];
    }
    return result;
}


// Return the number of pages available for printing
- (BOOL)knowsPageRange:(NSRangePointer)range
{
    // happy paginating:
    
    // reset everything
    bzero(&I_measures, sizeof(I_measures));
    I_measures.emailAIMLabelWidth   = MAX([NSLocalizedString(@"PrintExportLegendEmailLabel", @"Label for Email in legend in Print and Export") sizeWithAttributes:S_contactLabelAttributes].width,
                                          [NSLocalizedString(@"PrintExportLegendAIMLabel", @"Label for AIM in legend in Print and Export") sizeWithAttributes:S_contactLabelAttributes].width);

    I_pagesWithLegend = 0;
    I_pagesWithFullLegend = 0;
    I_pageCount = 0;
    [I_contributorArray removeAllObjects];
    [I_visitorArray removeAllObjects];
    
    [[[[self subviews] copy] autorelease] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [I_textStorage setAttributedString:[(FoldableTextStorage *)[I_document textStorage] fullTextStorage]];
    
    NSPrintInfo *printInfo = [[NSPrintOperation currentOperation] printInfo];
    NSDictionary *printDictionary = [I_document printOptions];
    //NSLog(@"PrintInfo: %@",[[printInfo dictionary] description]);
    
    SyntaxHighlighter *highlighter = nil;
    
    if ([[printDictionary objectForKey:@"SEEHighlightSyntax"] boolValue]) {
        highlighter = [[I_document documentMode] syntaxHighlighter];
    }
    
    // since folding we always copy first to have a real NSTextStorage that can be layouted
    if (highlighter) {
        while (![highlighter colorizeDirtyRanges:I_textStorage ofDocument:I_document]) ;
    }
    //    BOOL copyFirst=([[printDictionary objectForKey:@"SEEHighlightSyntax"] boolValue] != [I_document highlightsSyntax]);
    //
    //    NSInteger i=0;
    //    for (i=0;i<2;i++) {
    //        if (copyFirst) {
    //            I_textStorage = [[NSTextStorage alloc] initWithAttributedString:[I_textStorage autorelease]];
    //        } else {
    //            if (highlighter) {
    //                while (![highlighter colorizeDirtyRanges:I_textStorage ofDocument:I_document]);
    //            }
    //        }
    //        copyFirst=!copyFirst;
    //    }
    //
    
    CGFloat legendHeight = 0.0;
    CGFloat lineNumberSize = 8.0;
    NSRange lastGlyphRange = NSMakeRange(NSNotFound, 0);
    BOOL showLineNumbers = [[printDictionary objectForKey:@"SEELineNumbers"] boolValue];
    
    [I_textStorage beginEditing];
    BOOL needToEnforceWhiteBackground =
    ([[printDictionary objectForKey:@"SEEWhiteBackground"] boolValue] &&
     [[[I_document documentMode] defaultForKey:DocumentModeBackgroundColorIsDarkPreferenceKey] boolValue]);
    
    if (![[printDictionary objectForKey:@"SEEHighlightSyntax"] boolValue] || !highlighter) {
        NSRange wholeRange = NSMakeRange(0, [I_textStorage length]);
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    needToEnforceWhiteBackground ? [NSColor blackColor]:[I_document documentForegroundColor], NSForegroundColorAttributeName,
                                    [I_document fontWithTrait:0], NSFontAttributeName,
                                    [NSNumber numberWithFloat:0.], NSObliquenessAttributeName,
                                    [NSNumber numberWithFloat:0.], NSStrokeWidthAttributeName,
                                    nil];
        [I_textStorage addAttributes:attributes range:wholeRange];
    }
    
    if (needToEnforceWhiteBackground && highlighter) {
        if ([[printDictionary objectForKey:@"SEEUseCustomFont"] boolValue]) {
            NSDictionary *fontAttributes = [printDictionary objectForKey:@"SEEFontAttributes"];
            NSFont *newFont = [NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
            
            if (!newFont) newFont = [NSFont userFixedPitchFontOfSize:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
            I_baseFont = [newFont retain];
        } else {
            NSFont *newFont = [I_document fontWithTrait:0];
            
            if ([[printDictionary objectForKey:@"SEEResizeDocumentFont"] boolValue]) {
                newFont = [[NSFontManager sharedFontManager] convertFont:newFont toSize:[[printDictionary objectForKey:@"SEEResizeDocumentFontTo"] floatValue]];
            }
            NSLog(@"%s %@", __FUNCTION__, newFont);
            I_baseFont = [newFont retain];
        }
        [highlighter updateStylesInTextStorage:I_textStorage ofDocument:self];
    } else {
        if (![[printDictionary objectForKey:@"SEEUseCustomFont"] boolValue]) {
            if ([[printDictionary objectForKey:@"SEEResizeDocumentFont"] boolValue]) {
                NSFontManager *fontManager = [NSFontManager sharedFontManager];
                CGFloat newSize = [[printDictionary objectForKey:@"SEEResizeDocumentFontTo"] floatValue];
                
                if (newSize <= 0.) newSize = 4.;
                
                if (lineNumberSize > newSize) lineNumberSize = newSize;
                NSRange wholeRange = NSMakeRange(0, [I_textStorage length]);
                
                if (NSMaxRange(wholeRange) > 0) {
                    NSRange foundRange = NSMakeRange(0, 0);
                    
                    while (NSMaxRange(wholeRange) > NSMaxRange(foundRange)) {
                        NSFont *font = [I_textStorage attribute:NSFontAttributeName atIndex:NSMaxRange(foundRange) longestEffectiveRange:&foundRange inRange:wholeRange];
                        font = [fontManager convertFont:font toSize:newSize];
                        [I_textStorage addAttribute:NSFontAttributeName value:font range:foundRange];
                    }
                }
            }
        } else {
            NSFontManager *fontManager = [NSFontManager sharedFontManager];
            NSDictionary *fontAttributes = [printDictionary objectForKey:@"SEEFontAttributes"];
            NSFont *newFont = [NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
            
            if (!newFont) newFont = [NSFont userFixedPitchFontOfSize:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
            
            if (lineNumberSize > [newFont pointSize]) lineNumberSize = [newFont pointSize];
            NSRange wholeRange = NSMakeRange(0, [I_textStorage length]);
            
            if (NSMaxRange(wholeRange) > 0) {
                NSRange foundRange = NSMakeRange(0, 0);
                
                while (NSMaxRange(wholeRange) > NSMaxRange(foundRange)) {
                    NSFont *font = [I_textStorage attribute:NSFontAttributeName atIndex:NSMaxRange(foundRange) longestEffectiveRange:&foundRange inRange:wholeRange];
                    font = [fontManager convertFont:newFont toHaveTrait:[fontManager traitsOfFont:font]];
                    [I_textStorage addAttribute:NSFontAttributeName value:font range:foundRange];
                }
            }
        }
    }
    I_layoutManager = [NSLayoutManager new];
    [I_textStorage addLayoutManager:I_layoutManager];
    NSTypesetter *typesetter = [PrintTypesetter new];
    [I_layoutManager setTypesetter:typesetter];
    [typesetter release];
    
    I_pageSize = [printInfo paperSize];
    I_textContainerSize = I_pageSize;
    // NSLog(@"left:%f, top:%f, right:%f, bottom:%f",[[printDictionary objectForKey:NSPrintLeftMargin] floatValue],[[printDictionary objectForKey:NSPrintTopMargin] floatValue],[[printDictionary objectForKey:NSPrintRightMargin] floatValue],[[printDictionary objectForKey:NSPrintBottomMargin] floatValue]);
    I_textContainerSize.width  -= [[printDictionary objectForKey:NSPrintLeftMargin] floatValue] + [[printDictionary objectForKey:NSPrintRightMargin] floatValue];
    I_textContainerSize.height -= [[printDictionary objectForKey:NSPrintTopMargin] floatValue] + [[printDictionary objectForKey:NSPrintBottomMargin] floatValue];
    
    I_textContainerOrigin.x = [[printDictionary objectForKey:NSPrintLeftMargin] floatValue];
    I_textContainerOrigin.y = [[printDictionary objectForKey:NSPrintTopMargin] floatValue];
    
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
    if ([[printDictionary objectForKey:@"SEEPageHeader"] boolValue]) {
        I_headerTextView = [[NSTextView alloc] initWithFrame:NSMakeRect([[printDictionary objectForKey:NSPrintLeftMargin] floatValue], [[printDictionary objectForKey:NSPrintRightMargin] floatValue], I_textContainerSize.width, I_textContainerSize.height)];
        [[I_headerTextView textContainer] setLineFragmentPadding:0.];
        [I_headerTextView setTextContainerInset:NSMakeSize(0., 0.)];
        [I_headerTextView setDrawsBackground:NO];
        
        NSFont *headerFont = [NSFont fontWithName:@"Helvetica" size:10.];
        
        if (!headerFont) headerFont = [NSFont systemFontOfSize:10.];
        NSMutableDictionary *headerAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSColor blackColor], NSForegroundColorAttributeName, headerFont, NSFontAttributeName, nil];
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [paragraphStyle setTabStops:[NSArray array]];
        NSTextTab *tab = [[NSTextTab alloc] initWithType:NSRightTabStopType location:I_textContainerSize.width - 1.];
        [paragraphStyle addTabStop:tab];
        [tab release];
        [headerAttributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
        [paragraphStyle release];
        [self setHeaderAttributes:headerAttributes];
        
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
        [dateFormatter setDateStyle:NSDateFormatterFullStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        NSString *date = [NSString stringWithFormat:NSLocalizedString(@"PrintDate: %@", @"Date Information in Print Header"), [dateFormatter stringFromDate:[NSDate date]]];
        
        NSString *filenameString = [[printDictionary objectForKey:@"SEEPageHeaderFullPath"] boolValue] ? [[I_document fileURL] path] : [self printJobTitle];
        
        if ([[printDictionary objectForKey:@"SEEPageHeaderFilename"] boolValue] &&
            [[printDictionary objectForKey:@"SEEPageHeaderCurrentDate"] boolValue])
        {
            [self setHeaderFormatString:[NSString stringWithFormat:@"%1$@\n%3$@\t%2$@", filenameString, @"%1$@", date]];
        } else if ([[printDictionary objectForKey:@"SEEPageHeaderFilename"] boolValue]) {
            [self setHeaderFormatString:[NSString stringWithFormat:@"%1$@\t%2$@", filenameString, @"%1$@"]];
        } else if ([[printDictionary objectForKey:@"SEEPageHeaderCurrentDate"] boolValue]) {
            [self setHeaderFormatString:[NSString stringWithFormat:@"%1$@\t%2$@", date, @"%1$@"]];
        } else {
            [self setHeaderFormatString:@"\t%1$@"];
        }
        NSTextStorage *textStorage = [I_headerTextView textStorage];
        [textStorage replaceCharactersInRange:NSMakeRange(0, 0)
                                   withString:
         [NSString stringWithFormat:[self headerFormatString],
          NSLocalizedString(@"PrintPage %d of %d", @"Page Information in Print Header")]];
        [textStorage addAttributes:[self headerAttributes] range:NSMakeRange(0, [textStorage length])];
        
        // determine the space we need
        NSLayoutManager *layoutManager = [I_headerTextView layoutManager];
        NSRect boundingRect =
        [layoutManager boundingRectForGlyphRange:[layoutManager glyphRangeForCharacterRange:NSMakeRange(0, [textStorage length]) actualCharacterRange:NULL]
                                 inTextContainer:[[layoutManager textContainers] objectAtIndex:0]];
        
        [I_headerTextView setFrameSize:NSMakeSize(I_textContainerSize.width, boundingRect.size.height + 4.)];
        I_textContainerOrigin.y   += boundingRect.size.height + 10.;
        I_textContainerSize.height -= boundingRect.size.height + 10.;
        
        [self addSubview:I_headerTextView];
    }
    
    // Contributors and Visitors at the first page
    if ([[printDictionary objectForKey:@"SEEParticipants"] boolValue]) {
        NSSet *contributorIDs = [I_document userIDsOfContributors];
        NSEnumerator *contributorEnumerator = [[[I_document session] contributors] objectEnumerator];
        TCMMMUser *contributor = nil;
        
        while ((contributor = [contributorEnumerator nextObject])) {
            NSSize nameSize = [[contributor name] sizeWithAttributes:S_nameAttributes];
            NSSize aimSize  = [[[contributor properties] objectForKey:@"AIM"] sizeWithAttributes:S_contactAttributes];
            NSSize emailSize = [[[contributor properties] objectForKey:@"Email"] sizeWithAttributes:S_contactAttributes];
            
            if ([contributorIDs containsObject:[contributor userID]]) {
                [I_contributorArray addObject:contributor];
                I_measures.contributorNameWidth = MAX(nameSize.width, I_measures.contributorNameWidth);
                I_measures.contributorAIMWidth  = MAX(aimSize.width, I_measures.contributorAIMWidth);
                I_measures.contributorEmailWidth = MAX(emailSize.width, I_measures.contributorEmailWidth);
            } else {
                [I_visitorArray addObject:contributor];
                I_measures.visitorNameWidth     = MAX(nameSize.width, I_measures.visitorNameWidth);
                I_measures.visitorAIMWidth      = MAX(aimSize.width, I_measures.visitorAIMWidth);
                I_measures.visitorEmailWidth    = MAX(emailSize.width, I_measures.visitorEmailWidth);
            }
        }
        
        NSSortDescriptor *nameDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"name"
                                                                        ascending:YES
                                                                         selector:@selector(caseInsensitiveCompare:)] autorelease];
        [I_contributorArray sortUsingDescriptors:[NSArray arrayWithObject:nameDescriptor]];
        [I_visitorArray sortUsingDescriptors:[NSArray arrayWithObject:nameDescriptor]];
        
        I_measures.contributorWidth = 2 * LEGENDIMAGEPADDING + I_measures.contributorNameWidth +
        ([[printDictionary objectForKey:@"SEEParticipantImages"] boolValue] ? LEGENDTABLEENTRYHEIGHT : 0) +
        ([[printDictionary objectForKey:@"SEEParticipantsAIMAndEmail"] boolValue] ? MAX(I_measures.contributorAIMWidth, I_measures.contributorEmailWidth) + 2 * LEGENDIMAGEPADDING + I_measures.emailAIMLabelWidth : 0);
        
        
        I_measures.visitorWidth = 2 * LEGENDIMAGEPADDING + I_measures.visitorNameWidth +
        ([[printDictionary objectForKey:@"SEEParticipantImages"] boolValue] ? LEGENDTABLEENTRYHEIGHT : 0) +
        ([[printDictionary objectForKey:@"SEEParticipantsAIMAndEmail"] boolValue] ? MAX(I_measures.visitorAIMWidth, I_measures.visitorEmailWidth) + 2 * LEGENDIMAGEPADDING + I_measures.emailAIMLabelWidth : 0);
        
        if ([[printDictionary objectForKey:@"SEEParticipantsVisitors"] boolValue]) {
            CGFloat visitorHeight = LEGENDTABLEHEADERHEIGHT + LEGENDTABLEENTRYHEIGHT *[I_visitorArray count];
            
            if (I_measures.contributorWidth + 2 * LEGENDIMAGEPADDING + I_measures.visitorWidth > I_textContainerSize.width) {
                legendHeight += visitorHeight;
            } else {
                legendHeight = MAX(legendHeight, visitorHeight);
            }
        }
        I_contributorCount = [I_contributorArray count];
        I_visitorCount = [[printDictionary objectForKey:@"SEEParticipantsVisitors"] boolValue] ? [I_visitorArray count] : 0;
        I_contributorIndex = 0;
        I_visitorIndex = 0;
        
        NSInteger contributorCount = I_contributorCount;
        NSInteger visitorCount = I_visitorCount;
        
        while (contributorCount + visitorCount > 0) {
            NSSize maxSize = I_textContainerSize;
            legendHeight = 0.;
            
            if (contributorCount) legendHeight = LEGENDTABLEHEADERHEIGHT + LEGENDTABLEENTRYHEIGHT * contributorCount;
            
            if (visitorCount > 0) {
                CGFloat visitorHeight = LEGENDTABLEHEADERHEIGHT + LEGENDTABLEENTRYHEIGHT * visitorCount;
                
                if (maxSize.width < I_measures.contributorWidth + 2 * LEGENDIMAGEPADDING + I_measures.visitorWidth) {
                    legendHeight += (legendHeight > 0 ? 5. : 0.) + visitorHeight;
                } else {
                    legendHeight = MAX(legendHeight, visitorHeight);
                }
            }
            
            if (legendHeight < I_textContainerSize.height) {
                // all did fit
                contributorCount = 0;
                visitorCount = 0;
            } else {
                // try to fit all on the page
                NSPoint cursor = NSMakePoint(0., 0.);
                
                while (YES) {
                    BOOL columnHadContributors = NO;
                    
                    if (contributorCount > 0) {
                        if (cursor.x + I_measures.contributorWidth > maxSize.width && cursor.x > 0) {
                            // rest of page not wide enough
                            break;
                        } else {
                            cursor.y += LEGENDTABLEHEADERHEIGHT;
                            NSInteger maxEntries = (maxSize.height - cursor.y) / LEGENDTABLEENTRYHEIGHT;
                            
                            if (maxEntries > contributorCount) {
                                cursor.y += contributorCount * LEGENDTABLEENTRYHEIGHT + 5.;
                                contributorCount = 0;
                                columnHadContributors = YES;
                            } else {
                                cursor.y = 0;
                                contributorCount -= maxEntries;
                                cursor.x += I_measures.contributorWidth + 5.;
                                continue;
                            }
                        }
                    }
                    
                    if (visitorCount > 0) {
                        if (cursor.x + I_measures.visitorWidth > maxSize.width && cursor.x > 0) {
                            // rest of page not wide enough
                            break;
                        } else {
                            cursor.y += LEGENDTABLEHEADERHEIGHT;
                            NSInteger maxEntries = (maxSize.height - cursor.y) / LEGENDTABLEENTRYHEIGHT;
                            
                            if (maxEntries > visitorCount) {
                                cursor.y += visitorCount * LEGENDTABLEENTRYHEIGHT + 5.;
                                visitorCount = 0;
                                break;
                            } else {
                                cursor.y = 0;
                                visitorCount -= maxEntries;
                                cursor.x += MAX((columnHadContributors ? I_measures.contributorWidth : 0.), I_measures.visitorWidth);
                                continue;
                            }
                        }
                    }
                    break;
                }
                I_pagesWithFullLegend++;
            }
            I_pagesWithLegend++;
        }
        legendHeight += 10.;
    }
    
    // setup Paragraph Style and add line Numbers
    if ([I_textStorage length] > 0) {
        NSMutableParagraphStyle *paragraphStyle = [[I_textStorage attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL] mutableCopy];
        
        [paragraphStyle setTabStops:[NSArray array]];
        CGFloat tabStart = 0.;
        
        if (showLineNumbers) {
            [paragraphStyle setHeadIndent:30.];
            [paragraphStyle setFirstLineHeadIndent:0.];
            NSTextTab *tab = [[NSTextTab alloc] initWithType:NSRightTabStopType location:25.];
            [paragraphStyle addTabStop:tab];
            [tab release];
            tab = [[NSTextTab alloc] initWithType:NSLeftTabStopType location:30.];
            [paragraphStyle addTabStop:tab];
            [tab release];
            tabStart = 30.;
        }
        // Create correct tabstops for tab users
        CGFloat tabstopPosition = tabStart;
        NSFont *font = [I_textStorage attribute:NSFontAttributeName atIndex:0 effectiveRange:nil];
        CGFloat charWidth = [@" " sizeWithAttributes : [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]].width;
        
        if (charWidth <= 0) {
            charWidth = [font maximumAdvancement].width;
        }
        CGFloat tabWidth = charWidth *[I_document tabWidth];
        
        while (tabstopPosition + tabWidth < I_textContainerSize.width) {
            tabstopPosition += tabWidth;
            NSTextTab *tab = [[NSTextTab alloc] initWithType:NSLeftTabStopType location:tabstopPosition];
            [paragraphStyle addTabStop:tab];
            [tab release];
        }
        
        // to provide the space four our annotations if needed
        [paragraphStyle setLineSpacing:12.];
        
        
        //        NSLog(@"TabStops: %@",[[paragraphStyle tabStops] description]);
        
        NSFont *usedFont = [I_textStorage attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
        
        if (showLineNumbers) {
            NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor], NSForegroundColorAttributeName, [NSFont userFixedPitchFontOfSize:lineNumberSize], NSFontAttributeName, nil];
            
            NSInteger lineNumber = 1;
            NSString *lineNumberString = nil;
            NSRange lineRange = NSMakeRange(0, 0);
            do {
                lineRange.location = NSMaxRange(lineRange);
                lineRange.length = 0;
                lineNumberString = [[NSString alloc] initWithFormat:@"\t%ld:\t", lineNumber];
                [I_textStorage replaceCharactersInRange:lineRange withString:lineNumberString];
                lineRange.length = [lineNumberString length];
                [I_textStorage addAttributes:attributes range:lineRange];
                [I_textStorage removeAttribute:WrittenByUserIDAttributeName range:lineRange];
                [I_textStorage removeAttribute:ChangedByUserIDAttributeName range:lineRange];
                lineRange = [[I_textStorage string] lineRangeForRange:lineRange];
                [lineNumberString release];
                lineNumber++;
            } while (NSMaxRange(lineRange) < [I_textStorage length]);
        }
        
        if ([[[I_document documentMode] defaultForKey:DocumentModeIndentWrappedLinesPreferenceKey] boolValue] && [I_textStorage length]) {
            unsigned length = [I_textStorage length];
            NSString *string = [I_textStorage string];
            NSFont *font = usedFont;
            NSInteger tabWidth = [I_document tabWidth];
            CGFloat characterWidth = [@" " sizeWithAttributes :[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]].width;
            NSInteger indentWrappedCharacterAmount = [[[I_document documentMode] defaultForKey:DocumentModeIndentWrappedLinesCharacterAmountPreferenceKey] intValue];
            // NSLog(@"%s indenting with %d characters",__FUNCTION__,indentWrappedCharacterAmount);
            
            // look at all the lines and fix the indention
            NSRange myRange = NSMakeRange(0, 0);
            do {
                myRange = [string lineRangeForRange:NSMakeRange(NSMaxRange(myRange), 0)];
                
                if (myRange.length > 0) {
                    NSParagraphStyle *style = [I_textStorage attribute:NSParagraphStyleAttributeName atIndex:myRange.location effectiveRange:NULL];
                    
                    if (style) {
                        unsigned whitespaceStartLocation = showLineNumbers ? [string rangeOfString:@"\t" options:0 range:NSMakeRange(myRange.location + 1, myRange.length - 1)].location + 1 : myRange.location;
                        CGFloat desiredHeadIndent = characterWidth *[string detabbedLengthForRange:[string rangeOfLeadingWhitespaceStartingAt:whitespaceStartLocation] tabWidth:tabWidth] + [style firstLineHeadIndent] + indentWrappedCharacterAmount * characterWidth;
                        
                        if (ABS([style headIndent] - desiredHeadIndent) > 0.01) {
                            NSMutableParagraphStyle *newStyle = [paragraphStyle mutableCopy];
                            [newStyle setHeadIndent:desiredHeadIndent + tabStart];
                            [I_textStorage addAttribute:NSParagraphStyleAttributeName value:newStyle range:myRange];
                            [newStyle release];
                        } else {
                            [I_textStorage addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:myRange];
                        }
                    }
                }
            } while (NSMaxRange(myRange) < length);
        } else {
            [I_textStorage addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [I_textStorage length])];
        }
        [paragraphStyle release];
        [I_textStorage endEditing];
        
        // prepare for Annotation and Background
        TCMMMUserManager *userManager = [TCMMMUserManager sharedInstance];
        
        if ([[printDictionary objectForKey:@"SEEColorizeChangeMarks"] boolValue] ||
            [[printDictionary objectForKey:@"SEEAnnotateChangeMarks"] boolValue])
        {
            NSRange foundRange = NSMakeRange(0, 0);
            NSRange wholeRange = NSMakeRange(0, [I_textStorage length]);
            
            while (NSMaxRange(wholeRange) > NSMaxRange(foundRange)) {
                NSString *userID = [I_textStorage attribute:ChangedByUserIDAttributeName atIndex:NSMaxRange(foundRange) longestEffectiveRange:&foundRange inRange:wholeRange];
                
                if (userID) {
                    if ([[printDictionary objectForKey:@"SEEAnnotateChangeMarks"] boolValue]) {
                        [I_textStorage addAttribute:@"AnnotateID" value:userID range:foundRange];
                    }
                    
                    if ([[printDictionary objectForKey:@"SEEColorizeChangeMarks"] boolValue]) {
                        TCMMMUser *user = [userManager userForUserID:userID];
                        NSColor *changeColor = [user changeColor];
                        NSColor *userBackgroundColor = [[[printDictionary objectForKey:@"SEEWhiteBackground"] boolValue] ? [NSColor whiteColor]:[I_document documentBackgroundColor]
                                                        blendedColorWithFraction:
                                                        [standardUserDefaults floatForKey:ChangesSaturationPreferenceKey] / 100.
                                                        ofColor                 :changeColor];
                        [I_textStorage addAttribute:@"PrintBackgroundColour" value:userBackgroundColor range:foundRange];
                    }
                }
            }
        }
        
        if ([[printDictionary objectForKey:@"SEEColorizeWrittenBy"] boolValue] ||
            [[printDictionary objectForKey:@"SEEAnnotateWrittenBy"] boolValue])
        {
            NSRange foundRange = NSMakeRange(0, 0);
            NSRange wholeRange = NSMakeRange(0, [I_textStorage length]);
            
            while (NSMaxRange(wholeRange) > NSMaxRange(foundRange)) {
                NSString *userID = [I_textStorage attribute:WrittenByUserIDAttributeName
                                   atIndex                 :NSMaxRange(foundRange)
                                   longestEffectiveRange   :&foundRange
                                   inRange                 :wholeRange];
                
                if (userID) {
                    if ([[printDictionary objectForKey:@"SEEAnnotateWrittenBy"] boolValue]) {
                        [I_textStorage addAttribute:@"AnnotateID" value:userID range:foundRange];
                    }
                    
                    if ([[printDictionary objectForKey:@"SEEColorizeWrittenBy"] boolValue]) {
                        TCMMMUser *user = [userManager userForUserID:userID];
                        NSColor *changeColor = [user changeColor];
                        NSColor *userBackgroundColor = [[[printDictionary objectForKey:@"SEEWhiteBackground"] boolValue] ? [NSColor whiteColor]:[I_document documentBackgroundColor]
                                                        blendedColorWithFraction:
                                                        [standardUserDefaults floatForKey:ChangesSaturationPreferenceKey] / 100.
                                                        ofColor                 :changeColor];
                        [I_textStorage addAttribute:@"PrintBackgroundColour" value:userBackgroundColor range:foundRange];
                    }
                }
            }
        }
        // ensure last line has a linebreak, for annotations to be typeset correctly
        NSUInteger startIndex, lineEndIndex, contentsEndIndex;
        [[I_textStorage string] getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:NSMakeRange([I_textStorage length] - 1, 0)];
        
        if (contentsEndIndex == lineEndIndex) {
            [I_textStorage replaceCharactersInRange:NSMakeRange([I_textStorage length], 0) withString:@"\n"];
        }
        lastGlyphRange = [I_layoutManager glyphRangeForCharacterRange:NSMakeRange([I_textStorage length] - 1, 1) actualCharacterRange:0];
    } else {
        [I_textStorage endEditing];
    }
    
    BOOL overflew = NO;
    [self setFrame:NSMakeRect(0., 0., I_pageSize.width, 0.)];
    NSPoint origin = I_textContainerOrigin;
    do {
        BOOL leftPage = I_pageCount % 2 && [[printDictionary objectForKey:@"SEEFacingPages"] boolValue];
        overflew = NO;
        
        if (I_pageCount < I_pagesWithLegend - 1) {
            overflew = YES;
        } else {
            NSSize containerSize = I_textContainerSize;
            
            if (I_pageCount == I_pagesWithLegend - 1) {
                containerSize.height -= legendHeight;
            }
            
            if (containerSize.height > 0) {
                NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:containerSize];
                NSTextView *textview = [[PrintTextView alloc] initWithFrame:NSMakeRect(leftPage ? [[printDictionary objectForKey:NSPrintRightMargin] floatValue] : origin.x,
                                                                                       origin.y + ((I_pageCount == I_pagesWithLegend - 1) ? legendHeight : 0.),
                                                                                       containerSize.width,
                                                                                       containerSize.height)
                                                              textContainer:textContainer];
                
                [textview setHorizontallyResizable:NO];
                [textview setVerticallyResizable:NO];
                [textview setBackgroundColor:[[printDictionary objectForKey:@"SEEWhiteBackground"] boolValue] ? [NSColor whiteColor]:[I_document documentBackgroundColor]];
                [I_layoutManager addTextContainer:textContainer];
                [self addSubview:textview];
                NSRange glyphRange = [I_layoutManager glyphRangeForTextContainer:textContainer];
                
                if (lastGlyphRange.location != NSNotFound &&
                    NSMaxRange(glyphRange) != NSMaxRange(lastGlyphRange))
                {
                    overflew = YES;
                }
                [textContainer release];
                [textview release];
            } else {
                overflew = YES;
            }
        }
        origin.y += I_pageSize.height;
        I_pageCount += 1;
        NSRect frame = [self frame];
        frame.size.height += I_pageSize.height;
        [self setFrame:frame];
    } while (overflew);
    
    range->location = 1;
    range->length = I_pageCount;
    return YES;
}


- (void)beginPageInRect:(NSRect)aRect atPlacement:(NSPoint)location
{
    // NSLog(@"- (void)beginPageInRect:%@ atPlacement:%@",NSStringFromRect(aRect),NSStringFromPoint(location));
    [super beginPageInRect:aRect atPlacement:NSMakePoint(0., 0.)];
}


- (void)drawUser:(TCMMMUser *)aUser atPoint:(NSPoint)point visitor:(BOOL)isVisitor
{
    NSAttributedString *emailLabel = [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"PrintExportLegendEmailLabel", @"Label for Email in legend in Print and Export") attributes:S_contactLabelAttributes] autorelease];
    NSAttributedString *aimLabel = [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"PrintExportLegendAIMLabel", @"Label for AIM in legend in Print and Export") attributes:S_contactLabelAttributes] autorelease];
    NSAttributedString *newline = [[[NSAttributedString alloc] initWithString:@"\n" attributes:S_contactLabelAttributes] autorelease];
    
    static NSMutableAttributedString *mutableAttributedString = nil;
    
    if (!mutableAttributedString) {
        mutableAttributedString = [NSMutableAttributedString new];
    }
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *printDictionary = [I_document printOptions];
    
    if (!isVisitor &&
        ([[printDictionary objectForKey:@"SEEColorizeChangeMarks"] boolValue] ||
         [[printDictionary objectForKey:@"SEEColorizeWrittenBy"]   boolValue]))
    {
        NSColor *changeColor = [aUser changeColor];
        NSColor *userBackgroundColor = [[[printDictionary objectForKey:@"SEEWhiteBackground"] boolValue] ? [NSColor whiteColor]:[I_document documentBackgroundColor]
                                        blendedColorWithFraction:
                                        [standardUserDefaults floatForKey:ChangesSaturationPreferenceKey] / 100.
                                        ofColor                 :changeColor];
        [userBackgroundColor set];
        [NSBezierPath fillRect:NSMakeRect(point.x, point.y, (isVisitor ? I_measures.visitorNameWidth : I_measures.contributorNameWidth) + LEGENDIMAGEPADDING * 2 +
                                          ([[printDictionary objectForKey:@"SEEParticipantImages"] boolValue] ? LEGENDTABLEENTRYHEIGHT : 0),
                                          LEGENDTABLEENTRYHEIGHT)];
        [S_nameAttributes setObject:[[printDictionary objectForKey:@"SEEWhiteBackground"] boolValue] ? [NSColor blackColor]:[I_document documentForegroundColor] forKey:NSForegroundColorAttributeName];
    } else {
        [S_nameAttributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
    }
    NSPoint textPoint = point;
    
    if ([[printDictionary objectForKey:@"SEEParticipantImages"] boolValue]) {
        NSRect myPictureRect = NSMakeRect(point.x + LEGENDIMAGEPADDING, point.y + LEGENDIMAGEPADDING,
                                          LEGENDTABLEENTRYHEIGHT - 2 * LEGENDIMAGEPADDING,
                                          LEGENDTABLEENTRYHEIGHT - 2 * LEGENDIMAGEPADDING);
        NSImage *userImage = [aUser image];
        [userImage drawInRect:myPictureRect
                 fromRect    :NSMakeRect(0., 0., [userImage size].width, [userImage size].height)
                 operation   :NSCompositeSourceOver
                 fraction    :1.0 respectFlipped:YES hints:nil];
        textPoint.x += LEGENDTABLEENTRYHEIGHT;
    }
    textPoint.x += LEGENDIMAGEPADDING;
    
    textPoint.y += (LEGENDTABLEENTRYHEIGHT - 12.) / 2;
    
    [[aUser name] drawAtPoint:textPoint withAttributes:S_nameAttributes];
    textPoint.y -= (LEGENDTABLEENTRYHEIGHT - 12.) / 2;
    //                textPoint.y+=LEGENDIMAGEPADDING;
    textPoint.x += (isVisitor ? I_measures.visitorNameWidth : I_measures.contributorNameWidth) + LEGENDIMAGEPADDING * 2;
    
    if ([[printDictionary objectForKey:@"SEEParticipantsAIMAndEmail"] boolValue]) {
        [mutableAttributedString replaceCharactersInRange:NSMakeRange(0, [mutableAttributedString length]) withString:@""];
        
        NSString *aim = [[aUser properties] objectForKey:@"AIM"];
        
        if ([aim length] > 0) {
            //            [S_contactAttributes setObject:[NSURL URLWithString:@"http://www.dasgenie.com/"] forKey:NSLinkAttributeName];
            [mutableAttributedString appendAttributedString:aimLabel];
            [mutableAttributedString appendString:@" "];
            [mutableAttributedString appendAttributedString:[[[NSAttributedString alloc] initWithString:aim attributes:S_contactAttributes] autorelease]];
        }
        [mutableAttributedString appendAttributedString:newline];
        NSString *email = [[aUser properties] objectForKey:@"Email"];
        
        if ([email length] > 0) {
            [mutableAttributedString appendAttributedString:emailLabel];
            [mutableAttributedString appendString:@" "];
            [mutableAttributedString appendAttributedString:[[[NSAttributedString alloc] initWithString:email attributes:S_contactAttributes] autorelease]];
        }
        [mutableAttributedString drawAtPoint:textPoint];
    }
}


- (void)strokeLineFromPoint:(NSPoint)from toRelativePoint:(NSPoint)to width:(CGFloat)aWidth
{
    static NSBezierPath *path;
    
    if (!path) {
        path = [NSBezierPath new];
    }
    [path removeAllPoints];
    [path setLineWidth:aWidth];
    [path moveToPoint:from];
    [path relativeLineToPoint:to];
    [path stroke];
}


- (void)drawTableHeading:(NSString *)aHeading atPoint:(NSPoint)aPoint width:(CGFloat)aWidth
{
    [[NSColor colorWithCalibratedWhite:0.8 alpha:1.0] set];
    [NSBezierPath fillRect:NSMakeRect(aPoint.x, aPoint.y, aWidth, LEGENDTABLEHEADERHEIGHT)];
    [aHeading drawAtPoint:NSMakePoint(aPoint.x + LEGENDIMAGEPADDING, aPoint.y)
           withAttributes:S_tableHeadingAttributes];
    [[NSColor blackColor] set];
    [self strokeLineFromPoint:aPoint toRelativePoint:NSMakePoint(aWidth, 0.) width:0.3];
}


- (void)drawRect:(NSRect)rect
{
    NSDictionary *printDictionary = [I_document printOptions];
    
    NSInteger currentPage = (NSInteger)round(rect.origin.y / I_pageSize.height) + 1;
    BOOL leftPage = (currentPage - 1) % 2 && [[printDictionary objectForKey:@"SEEFacingPages"] boolValue];
    CGFloat originX = leftPage ? [[printDictionary objectForKey:NSPrintRightMargin] floatValue] : [[printDictionary objectForKey:NSPrintLeftMargin] floatValue];
    
    if ([[printDictionary objectForKey:@"SEEPageHeader"] boolValue]) {
        // Drawing code here.
        // NSLog(@"drawRect: %@", NSStringFromRect(rect));
        // move header to current location
        NSRect headerFrame = [I_headerTextView frame];
        headerFrame.origin.y = (currentPage - 1) * I_pageSize.height + [[printDictionary objectForKey:NSPrintTopMargin] floatValue];
        headerFrame.origin.x = originX;
        [I_headerTextView setFrame:headerFrame];
        
        // replace the page text
        NSTextStorage *textStorage = [I_headerTextView textStorage];
        [textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length])
                                   withString:
         [NSString stringWithFormat:[self headerFormatString],
          [NSString stringWithFormat:NSLocalizedString(@"PrintPage %d of %d", @"Page Information in Print Header"),
           currentPage, I_pageCount]
          ]
         ];
        [textStorage addAttributes:[self headerAttributes] range:NSMakeRange(0, [textStorage length])];
        
        [[NSColor blackColor] set];
        NSPoint basePoint = I_textContainerOrigin;
        basePoint.y += rect.origin.y - 7.0;
        basePoint.x = originX;
        [self strokeLineFromPoint:basePoint
                 toRelativePoint :NSMakePoint(I_textContainerSize.width, 0)
                 width           :0.5];
    }
    
    if ([[printDictionary objectForKey:@"SEEParticipants"] boolValue] && currentPage <= I_pagesWithLegend) {
        NSPoint origin = NSMakePoint(rect.origin.x + I_textContainerOrigin.x, (currentPage - 1) * I_pageSize.height + I_textContainerOrigin.y);
        origin.x = originX;
        
        if (currentPage <= I_pagesWithFullLegend) {
            NSSize maxSize = NSMakeSize(origin.x + I_textContainerSize.width, origin.y + I_textContainerSize.height);
            NSPoint cursor = origin;
            
            // fill as many legend items in there as you can!
            while (YES) {
                BOOL columnHadContributors = NO;
                
                if (I_contributorIndex < I_contributorCount) {
                    CGFloat tableWidth = I_measures.contributorWidth;
                    
                    if (cursor.x + tableWidth > maxSize.width && cursor.x > origin.x) {
                        // rest of page not wide enough
                        break;
                    } else {
                        [self drawTableHeading:NSLocalizedString(@"Contributors", @"Title for Contributors in Export and Print")
                                      atPoint :cursor
                                      width   :tableWidth];
                        cursor.y += LEGENDTABLEHEADERHEIGHT;
                        NSInteger alternate = 0;
                        
                        while (I_contributorIndex < I_contributorCount &&
                               maxSize.height - cursor.y >= LEGENDTABLEENTRYHEIGHT)
                        {
                            TCMMMUser *user = [I_contributorArray objectAtIndex:I_contributorIndex];
                            
                            NSRect myRect = NSMakeRect(cursor.x, cursor.y, tableWidth, LEGENDTABLEENTRYHEIGHT);
                            
                            if (alternate) {
                                [[NSColor colorWithCalibratedRed:237. / 255. green:243. / 255. blue:254. / 255. alpha:1.] set];
                                [NSBezierPath fillRect:myRect];
                            }
                            [self drawUser:user atPoint:cursor visitor:NO];
                            [[NSColor blackColor] set];
                            [self strokeLineFromPoint:cursor toRelativePoint:NSMakePoint(tableWidth, 0.) width:0.3];
                            I_contributorIndex++;
                            cursor.y += LEGENDTABLEENTRYHEIGHT;
                            alternate = 1 - alternate;
                        }
                        [self strokeLineFromPoint:cursor toRelativePoint:NSMakePoint(tableWidth, 0.) width:0.3];
                        
                        if (I_contributorIndex < I_contributorCount) {
                            cursor.x += tableWidth + 5.;
                            cursor.y = origin.y;
                            continue;
                        } else {
                            cursor.y += 5.;
                            columnHadContributors = YES;
                        }
                    }
                }
                
                if (I_visitorIndex < I_visitorCount) {
                    CGFloat tableWidth = I_measures.visitorWidth;
                    
                    if (cursor.x + tableWidth > maxSize.width && cursor.x > origin.x) {
                        // rest of page not wide enough
                        break;
                    } else {
                        if (cursor.y + LEGENDTABLEHEADERHEIGHT + LEGENDTABLEENTRYHEIGHT > maxSize.height) {
                            break;
                        } else {
                            [self drawTableHeading:NSLocalizedString(@"Visitors", @"Title for Visitors in Export and Print")
                                          atPoint :cursor
                                          width   :tableWidth];
                            cursor.y += LEGENDTABLEHEADERHEIGHT;
                            NSInteger alternate = 0;
                            
                            while (I_visitorIndex < I_visitorCount &&
                                   maxSize.height - cursor.y >= LEGENDTABLEENTRYHEIGHT)
                            {
                                TCMMMUser *user = [I_visitorArray objectAtIndex:I_visitorIndex];
                                
                                NSRect myRect = NSMakeRect(cursor.x, cursor.y, tableWidth, LEGENDTABLEENTRYHEIGHT);
                                
                                if (alternate) {
                                    [[NSColor colorWithCalibratedRed:237. / 255. green:243. / 255. blue:254. / 255. alpha:1.] set];
                                    [NSBezierPath fillRect:myRect];
                                }
                                [self drawUser:user atPoint:cursor visitor:YES];
                                [[NSColor blackColor] set];
                                [self strokeLineFromPoint:cursor toRelativePoint:NSMakePoint(tableWidth, 0.) width:0.3];
                                I_visitorIndex++;
                                cursor.y += LEGENDTABLEENTRYHEIGHT;
                                alternate = 1 - alternate;
                            }
                            [self strokeLineFromPoint:cursor toRelativePoint:NSMakePoint(tableWidth, 0.) width:0.3];
                            
                            if (I_visitorIndex < I_visitorCount) {
                                cursor.x += MAX(tableWidth, (columnHadContributors ? I_measures.contributorWidth : 0.)) + 5.;
                                cursor.y = origin.y;
                                continue;
                            }
                        }
                    }
                }
                break;
            }
        } else if (currentPage == I_pagesWithLegend) {
            NSPoint cursor = origin;
            NSInteger visitors = 0;
            
            for (visitors = 0; visitors < 2; visitors++) {
                CGFloat tableWidth = (visitors ? I_measures.visitorWidth : I_measures.contributorWidth);
                
                if (visitors) {
                    if ([[printDictionary objectForKey:@"SEEParticipantsVisitors"] boolValue]) {
                        if (I_measures.contributorWidth + 2 * LEGENDIMAGEPADDING + I_measures.visitorWidth < I_textContainerSize.width
                            && I_contributorCount - I_contributorIndex > 0)
                        {
                            cursor.x += I_measures.contributorWidth + 2 * LEGENDIMAGEPADDING;
                            cursor.y = origin.y;
                        }
                    } else {
                        break;
                    }
                }
                NSInteger count = visitors ? I_visitorCount : I_contributorCount;
                NSArray *userArray = visitors ? I_visitorArray : I_contributorArray;
                NSInteger index = visitors ? I_visitorIndex : I_contributorIndex;
                TCMMMUser *user = nil;
                NSInteger alternate = 0;
                
                if (index < count) {
                    [self drawTableHeading:(visitors)
                     ? NSLocalizedString(@"Visitors", @"Title for Visitors in Export and Print")
                                          :NSLocalizedString(@"Contributors", @"Title for Contributors in Export and Print")
                                  atPoint :cursor
                                  width   :tableWidth];
                    cursor.y += LEGENDTABLEHEADERHEIGHT;
                    
                    while (index < count) {
                        user = [userArray objectAtIndex:index];
                        NSRect myRect = NSMakeRect(cursor.x, cursor.y, tableWidth, LEGENDTABLEENTRYHEIGHT);
                        
                        if (alternate) {
                            [[NSColor colorWithCalibratedRed:237. / 255. green:243. / 255. blue:254. / 255. alpha:1.] set];
                            [NSBezierPath fillRect:myRect];
                        }
                        [self drawUser:user atPoint:cursor visitor:visitors];
                        
                        alternate = 1 - alternate;
                        [[NSColor blackColor] set];
                        [self strokeLineFromPoint:cursor toRelativePoint:NSMakePoint(tableWidth, 0.) width:0.3];
                        
                        cursor.y += LEGENDTABLEENTRYHEIGHT;
                        index++;
                    }
                    [[NSColor blackColor] set];
                    [self strokeLineFromPoint:cursor toRelativePoint:NSMakePoint(tableWidth, 0.) width:0.3];
                    
                    if (I_contributorCount - I_contributorIndex > 0) cursor.y += 5;
                }
            }
        }
    }
    //    [[NSColor redColor] set];
    //    NSRectFill(rect);
    //    [[NSColor greenColor] set];
    //    NSFrameRect(NSMakeRect(rect.origin.x+[[printDictionary objectForKey:NSPrintLeftMargin] floatValue],rect.origin.y+[[printDictionary objectForKey:NSPrintTopMargin] floatValue],I_textContainerSize.width,I_textContainerSize.height));
}


- (NSRect)rectForPage:(NSInteger)page
{
    NSRect result = NSMakeRect(0., I_pageSize.height * (page - 1),
                               I_pageSize.width, I_pageSize.height);
    
    // NSLog(@"rectForPage %d: %@",page,NSStringFromRect(result));
    return result;
}


- (BOOL)isFlipped
{
    return YES;
}


@end