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

@implementation FindAllController

- (id)initWithRegex:(OGRegularExpression*)regex andOptions:(unsigned)options {
    self = [super init];
    if (self) {
        I_regularExpression = [regex copy];
        I_options = options;

    }
    return self;
}

- (void)dealloc 
{
    [[self findAllPanel] orderOut:self];
    [I_regularExpression release];
    [super dealloc];
}

- (void)loadUI {
    if (!O_findAllPanel) {
        if (![NSBundle loadNibNamed:@"FindAll" owner:self]) {
            NSLog(@"Failed to load FindAll.nib");
            NSBeep();
        }
    }
}

- (NSPanel *)findAllPanel {
    if (!O_findAllPanel) [self loadUI];
    return O_findAllPanel;
}

- (void)setDocument:(PlainTextDocument *)aDocument {
    I_document = aDocument;
}

- (void) findAll
{
    [O_resultsController removeObjects:[O_resultsController arrangedObjects]]; //Clear arraycontroller
    [[self findAllPanel] makeKeyAndOrderFront:nil];
    OGRegularExpression *regex = I_regularExpression;
    unsigned options = I_options;

    if (I_document) {
        NSString *text = [[I_document textStorage] string];
        //NSRange selection = [target selectedRange];

        NSArray *matchArray = [regex allMatchesInString:text options:options range:NSMakeRange(0, [text length])];
        
        int i;
        int count = [matchArray count];
        [O_findResultsTextField setStringValue:[NSString stringWithFormat:@"%d found.",count]];
        for (i=0;i<count;i++) {
            OGRegularExpressionMatch *aMatch = [matchArray objectAtIndex:i];
            NSRange matchRange = [aMatch rangeOfMatchedString];
            TextStorage *textStorage = (TextStorage *)[I_document textStorage];
            NSNumber *line = [NSNumber numberWithInt:[textStorage lineNumberForLocation:matchRange.location]];
            
            NSRange lineRange = [[textStorage string] lineRangeForRange:matchRange];
            
            NSMutableAttributedString *aString = [[NSMutableAttributedString alloc] initWithString:[[textStorage string] substringWithRange:lineRange]];

            [aString addAttribute:NSBackgroundColorAttributeName value:[NSColor yellowColor] range:NSMakeRange(matchRange.location - lineRange.location, matchRange.length)];
            
            int subGroup;
            for(subGroup=1;subGroup<6;subGroup++) {
                if ([aMatch substringAtIndex:subGroup]) {
                    matchRange = [aMatch rangeOfSubstringAtIndex:subGroup];
                    NSColor *color;
                    if (subGroup==1) color = [NSColor orangeColor];
                    else if (subGroup==2) color = [NSColor greenColor];
                    else if (subGroup==3) color = [NSColor magentaColor];
                    else if (subGroup==4) color = [NSColor redColor];
                    else if (subGroup==5) color = [NSColor purpleColor];
                    [aString addAttribute:NSBackgroundColorAttributeName value:color range:NSMakeRange(matchRange.location - lineRange.location, matchRange.length)];
                } else break;
            }
            
            NSValue *aRange = [NSValue valueWithRange:[aMatch rangeOfMatchedString]]; 
            
            [O_resultsController addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                aString,@"foundString",
                                aRange,@"range",
                                line,@"line",nil]];
            [aString release];
        }
    }
}

#pragma mark -
#pragma mark ### Delegate methods ###

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if(I_document) {
        NSRange range = [[[[O_resultsController arrangedObjects] objectAtIndex:rowIndex] objectForKey:@"range"] rangeValue];
        [I_document selectRange:range];   
    } 
    return NO;
}
@end


@implementation NSAttributedString (NSAttributedStringComparing)

- (NSComparisonResult)compare:(NSAttributedString *)aString
{
    return [[self string] compare:[aString string]];
}    

@end
