//
//  FindAllController.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on Wed May 05 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "FindAllController.h"
#import <OgreKit/OgreKit.h>
#import "TextStorage.h"
#import "PlainTextDocument.h"
#import "SelectionOperation.h"

@implementation FindAllController

- (id)initWithRegex:(OGRegularExpression*)regex andRange:(NSRange)aRange {
    self = [super initWithWindowNibName:@"FindAll"];
    if (self) {
        I_regularExpression = [regex copy];
        //I_range = aRange;
    }
    return self;
}

- (void)dealloc 
{
    [[self window] orderOut:self];
    [I_regularExpression release];
    [super dealloc];
}

- (void)windowWillClose:(NSNotification *)aNotification {
    NSLog(@"close");
    [I_document removeFindAllController:self];
}

- (NSArray*) arrangedObjects
{
    return [O_resultsController arrangedObjects];
}

- (void)setDocument:(PlainTextDocument *)aDocument {
    I_document = aDocument;
    [[self window] setTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ - Find All",@"FindRegexPrefix"),[aDocument displayName]]];
}

- (void)windowDidLoad {
    [((NSPanel *)[self window]) setFloatingPanel:NO];
    [[self window] setHidesOnDeactivate:NO];
    [[self window] setDelegate:self];
    [O_findRegexTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Find: %@",@"FindRegexPrefix"),[I_regularExpression expressionString]]];
    [O_resultsTableView setDoubleAction:@selector(jumpToSelection:)];
    [O_resultsTableView setTarget:self];
}

- (void)findAll:(id)sender
{
    [O_progressIndicator startAnimation:nil];
    [self showWindow:self];
    [O_resultsController removeObjects:[O_resultsController arrangedObjects]]; //Clear arraycontroller
    OGRegularExpression *regex = I_regularExpression;

    if (I_document) {
        NSString *text = [[I_document textStorage] string];
                
        if ([regex syntax]==OgreSimpleMatchingSyntax) {
            unsigned options = OgreNoneOption;
            if ([regex options]&OgreIgnoreCaseOption) options = options | OgreIgnoreCaseOption;
            OGRegularExpression *simpleregex = [OGRegularExpression regularExpressionWithString:[regex expressionString]
                                                 options:options
                                                 syntax:OgreSimpleMatchingSyntax
                                                 escapeCharacter:[regex escapeCharacter]];
            regex = simpleregex;
        }
        
        NSArray *matchArray = [regex allMatchesInString:text options:[regex options] range:NSMakeRange(0,[text length])];
        
        int i;
        int count = [matchArray count];
        NSTableColumn* stringCol = [[O_resultsTableView tableColumns] objectAtIndex:1];
        int longestCol = 150;

        [O_findResultsTextField setStringValue:[NSString stringWithFormat:@"%d found.",count]];
        
        for (i=0;i<count;i++) {
            OGRegularExpressionMatch *aMatch = [matchArray objectAtIndex:i];
            NSRange matchRange = [aMatch rangeOfMatchedString];
            TextStorage *textStorage = (TextStorage *)[I_document textStorage];
            NSNumber *line = [NSNumber numberWithInt:[textStorage lineNumberForLocation:matchRange.location]];
            
            NSRange lineRange = [[textStorage string] lineRangeForRange:matchRange];
            
            NSMutableAttributedString *aString = [[NSMutableAttributedString alloc] initWithString:[[textStorage string] substringWithRange:lineRange]];

            [aString addAttribute:NSBackgroundColorAttributeName value:[[NSColor yellowColor] highlightWithLevel:0.5] range:NSMakeRange(matchRange.location - lineRange.location, matchRange.length)];
            [aString addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(matchRange.location - lineRange.location, matchRange.length)];
            
            int subGroup;
            for(subGroup=1;subGroup<6;subGroup++) {
                if ([aMatch substringAtIndex:subGroup]) {
                    matchRange = [aMatch rangeOfSubstringAtIndex:subGroup];
                    NSColor *color = nil;
                    if (subGroup==1) color = [[NSColor orangeColor] highlightWithLevel:0.6];
                    else if (subGroup==2) color = [[NSColor greenColor] highlightWithLevel:0.6];
                    else if (subGroup==3) color = [[NSColor magentaColor] highlightWithLevel:0.6];
                    else if (subGroup==4) color = [[NSColor redColor] highlightWithLevel:0.7];
                    else if (subGroup==5) color = [[NSColor purpleColor] highlightWithLevel:0.7];
                    [aString addAttribute:NSBackgroundColorAttributeName value:color range:NSMakeRange(matchRange.location - lineRange.location, matchRange.length)];
                } else break;
            }
            
            SelectionOperation *selOp = [[SelectionOperation new] autorelease];
            [selOp setSelectedRange:matchRange];
            
            [O_resultsController addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                aString,@"foundString",
                                selOp,@"selectionOperation",
                                line,@"line",nil]];

            NSSize stringSize = [aString size];
            if (longestCol<stringSize.width) {
                [stringCol setMinWidth:stringSize.width+5];
                longestCol = stringSize.width;
            }

            [aString release];
        }
            [O_resultsTableView tile];
    }
    [O_progressIndicator stopAnimation:nil];
}

- (void)jumpToSelection:(id)sender
{
    if(I_document) {
        NSRange range = [[[[O_resultsController selectedObjects] lastObject] objectForKey:@"selectionOperation"] selectedRange];
        if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)) {
            [I_document newView:self];
        }
        [I_document selectRange:range];   
    } 
}

@end


@implementation NSAttributedString (NSAttributedStringComparing)

- (NSComparisonResult)compare:(NSAttributedString *)aString
{
    return [[self string] compare:[aString string]];
}    

@end
