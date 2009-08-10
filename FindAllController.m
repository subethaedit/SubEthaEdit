//
//  FindAllController.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on Wed May 05 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "FindAllController.h"
#import <OgreKit/OgreKit.h>
#import "FoldableTextStorage.h"
#import "PlainTextDocument.h"
#import "FindReplaceController.h"


@implementation FindAllController

- (id)initWithRegex:(OGRegularExpression*)regex andRange:(NSRange)aRange {
    self = [super initWithWindowNibName:@"FindAll"];
    if (self) {
        I_regularExpression = [regex copy];
        // A non-scoped search is indicated by NSNotFound
        if (aRange.location != NSNotFound) {
            I_scopeSelectionOperation = [SelectionOperation new];
            [I_scopeSelectionOperation setSelectedRange:aRange];
        } 
    }
    return self;
}

- (void)dealloc 
{
    [[self window] orderOut:self];
    [I_regularExpression release];
    [I_scopeSelectionOperation release];
    [super dealloc];
}

- (void)windowWillClose:(NSNotification *)aNotification {
    //NSLog(@"close");
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
    [O_resultsTableView setDelegate:nil];

    [O_progressIndicator startAnimation:nil];
    [self showWindow:self];
    [O_resultsController removeObjects:[O_resultsController arrangedObjects]]; //Clear arraycontroller
    OGRegularExpression *regex = I_regularExpression;

    if (I_document) {
        NSString *text = [[(FoldableTextStorage *)[I_document textStorage] fullTextStorage] string];
                
        if ([regex syntax]==OgreSimpleMatchingSyntax) {
            unsigned options = OgreNoneOption;
            if ([regex options]&OgreIgnoreCaseOption) options = options | OgreIgnoreCaseOption;
            OGRegularExpression *simpleregex = [OGRegularExpression regularExpressionWithString:[regex expressionString]
                                                 options:options
                                                 syntax:OgreSimpleMatchingSyntax
                                                 escapeCharacter:[regex escapeCharacter]];
            regex = simpleregex;
        }
        
        NSRange scope;
        if (I_scopeSelectionOperation) 
            scope = [I_scopeSelectionOperation selectedRange];
        else 
            scope = NSMakeRange(0,[text length]);
        
        NSArray *matchArray = [regex allMatchesInString:text options:[regex options] range:scope];
        
        int i;
        int count = [matchArray count];
        NSTableColumn* stringCol = [[O_resultsTableView tableColumns] objectAtIndex:1];
        int longestCol = 150;
        
        NSString *statusString = [NSString stringWithFormat:NSLocalizedString(@"%d found.",@"Entries Found in FindAll Panel"),count];
        
        NSString *scopeString = [[[[FindReplaceController sharedInstance] scopePopup] itemAtIndex:(I_scopeSelectionOperation)?1:0] title];
                
        [O_findResultsTextField setStringValue:[NSString stringWithFormat:@"%@ (%@)",statusString,scopeString]];
        
        for (i=0;i<count;i++) {
            OGRegularExpressionMatch *aMatch = [matchArray objectAtIndex:i];
            NSRange matchRange = [aMatch rangeOfMatchedString];
            FullTextStorage *textStorage = [(FoldableTextStorage *)[I_document textStorage] fullTextStorage];
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
        if ([[self arrangedObjects] count] > 0) {
            [O_resultsController setSelectionIndex:0];
            NSRange range = [[[[O_resultsController arrangedObjects] objectAtIndex:0] objectForKey:@"selectionOperation"] selectedRange];
            [I_document selectRangeInBackground:range];
            [O_findAllPanel makeKeyAndOrderFront:self]; 
        }
    }
    [O_progressIndicator stopAnimation:nil];
    [O_resultsTableView setDelegate:self];

}

- (void)jumpToSelection:(id)sender
{
    if (I_document) {
        if ([[O_resultsController selectedObjects]count]>1) return;
        NSRange range = [[[[O_resultsController selectedObjects] lastObject] objectForKey:@"selectionOperation"] selectedRange];
        if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)) {
            [I_document newView:self];
        }
        [I_document selectRange:range];   
    } 
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	if ([[O_resultsController selectedObjects]count]==1) {
        NSRange range = [[[[O_resultsController selectedObjects] lastObject] objectForKey:@"selectionOperation"] selectedRange];
        [I_document selectRangeInBackground:range];
//        [O_findAllPanel makeKeyAndOrderFront:self]; 
    }
}

@end


@implementation NSAttributedString (NSAttributedStringComparing)

- (NSComparisonResult)compare:(NSAttributedString *)aString
{
    return [[self string] compare:[aString string]];
}    

@end
