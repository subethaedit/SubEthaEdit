//  FindAllController.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on Wed May 05 2004.


// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "FindAllController.h"
#import <OgreKit/OgreKit.h>
#import "FoldableTextStorage.h"
#import "PlainTextDocument.h"
#import "FindReplaceController.h"


@implementation FindAllController

+ (NSParagraphStyle *)listParagraphStyle {
    static NSParagraphStyle *result = nil;
    if (!result) {
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        NSMutableArray *tabStops = [NSMutableArray array];
        double distance = 10;
        for (NSInteger index = 1; index <= 100; index++) {
			NSTextTab *tab = [[NSTextTab alloc] initWithTextAlignment:NSLeftTextAlignment location:index * distance options:@{}];
            [tabStops addObject:tab];
        }
        [paragraphStyle setTabStops:tabStops];
        
        result = paragraphStyle;
    }
    
    return result;
}

- (instancetype)initWithFindAndReplaceContext:(SEEFindAndReplaceContext *)aFindAndReplaceContext {

    self = [super initWithWindowNibName:@"FindAll"];
    if (self) {
		self.findAndReplaceContext = aFindAndReplaceContext;
    }
    return self;
}

- (void)dealloc  {
    [[self window] orderOut:self];
}

- (void)windowWillClose:(NSNotification *)aNotification {
    [I_document removeFindAllController:self];
}

- (NSArray*)arrangedObjects {
    return [O_resultsController arrangedObjects];
}

- (void)setDocument:(PlainTextDocument *)aDocument {
    I_document = aDocument;
    [[self window] setTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ - Find All",@"FindRegexPrefix"),[aDocument displayName]]];
}

- (void)windowDidLoad {
	NSPanel *panel = (NSPanel *)self.window;
    [panel setFloatingPanel:NO];
    [panel setHidesOnDeactivate:NO];
    [panel setDelegate:self];
    [O_findRegexTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Find: %@",@"FindRegexPrefix"),self.findAndReplaceContext.findAndReplaceState.findString]];
    [O_resultsTableView setDoubleAction:@selector(jumpToSelection:)];
    [O_resultsTableView setTarget:self];
}

- (void)findAll:(id)sender {

    [O_resultsTableView setDelegate:nil];

    [O_progressIndicator startAnimation:nil];
    [self showWindow:self];

    [O_resultsController removeObjects:[O_resultsController arrangedObjects]]; //Clear arraycontroller

    if (I_document) {
        
        NSArray *matchArray = [self.findAndReplaceContext allMatches];
        
        int count = [matchArray count];
        NSTableColumn* stringCol = [[O_resultsTableView tableColumns] objectAtIndex:1];
        int longestCol = 150;
        
        NSString *statusString = [NSString stringWithFormat:NSLocalizedString(@"%d found.",@"Entries Found in FindAll Panel"),count];
/*
        NSString *scopeString = I_scopeSelectionOperation ? NSLocalizedStringWithDefaultValue(@"SELECTION_SCOPE_DESCRIPTION", nil, [NSBundle mainBundle], @"Selection", @"string describing the selection find scope") :
NSLocalizedStringWithDefaultValue(@"SELECTION_SCOPE_DOCUMENT", nil,[NSBundle mainBundle], @"Document", @"string describing the document find scope");
*/                
        [O_findResultsTextField setStringValue:[NSString stringWithFormat:@"%@",statusString]];
        
        for (OGRegularExpressionMatch *aMatch in matchArray) {
            NSRange matchRange = [aMatch rangeOfMatchedString];
            FullTextStorage *textStorage = [(FoldableTextStorage *)[I_document textStorage] fullTextStorage];
            NSNumber *line = [NSNumber numberWithInt:[textStorage lineNumberForLocation:matchRange.location]];
            
            NSRange lineRange = [[textStorage string] lineRangeForRange:matchRange];
            
            NSMutableAttributedString *aString = [[NSMutableAttributedString alloc] initWithString:[[textStorage string] substringWithRange:lineRange]];

            [aString addAttribute:NSBackgroundColorAttributeName value:[[NSColor yellowColor] highlightWithLevel:0.5] range:NSMakeRange(matchRange.location - lineRange.location, matchRange.length)];
            [aString addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(matchRange.location - lineRange.location, matchRange.length)];
            [aString addAttribute:NSParagraphStyleAttributeName value:[self.class listParagraphStyle] range:[aString TCM_fullLengthRange]];
            
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
            
            SelectionOperation *selOp = [SelectionOperation new];
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

- (void)jumpToSelection:(id)sender {
    if (I_document) {
        if ([[O_resultsController selectedObjects]count]>1) return;
        NSRange range = [[[[O_resultsController selectedObjects] lastObject] objectForKey:@"selectionOperation"] selectedRange];
        if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)) {
            [I_document newView:self];
			[I_document selectRange:range];
        } else {
			if (self.findAndReplaceContext.targetPlainTextEditor) {
				[self.findAndReplaceContext.targetPlainTextEditor selectRange:range];
			} else {
				[I_document selectRange:range];
			}
		}
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	if ([[O_resultsController selectedObjects]count]==1) {
        NSRange range = [[[[O_resultsController selectedObjects] lastObject] objectForKey:@"selectionOperation"] selectedRange];
		if (self.findAndReplaceContext.targetPlainTextEditor) {
			[self.findAndReplaceContext.targetPlainTextEditor selectRangeInBackground:range];
		} else {
			[I_document selectRangeInBackground:range];
		}
    }
}

@end


@implementation NSAttributedString (NSAttributedStringComparing)

- (NSComparisonResult)compare:(NSAttributedString *)aString
{
    return [[self string] compare:[aString string]];
}    

@end
