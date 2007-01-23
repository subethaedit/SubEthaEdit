//
//  EncodingDoctorDialog.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 11.09.06.
//  Copyright 2006-2007 TheCodingMonkeys. All rights reserved.
//

#import "EncodingDoctorDialog.h"
#import "SelectionOperation.h"
#import "TextStorage.h"
#import "PlainTextDocument.h"
#import "PlainTextWindowController.h"

@implementation EncodingDoctorDialog

- (id)initWithEncoding:(NSStringEncoding)anEncoding {
    if ((self=[super init])) {
        I_encoding = anEncoding;
    }
    return self;
}

- (NSString *)mainNibName {
    return @"EncodingDoctor";
}

- (void)mainViewDidLoad {
    [O_tableView setTarget: self];
    [O_tableView setAction:@selector(jumpToSelection:)];
    [O_tableView setDoubleAction:@selector(jumpToSelectionAndBecomeKey:)];
    [O_descriptionTextField setStringValue:[NSString stringWithFormat:[O_descriptionTextField stringValue],[NSString localizedNameOfStringEncoding:I_encoding]]];
    [self rerunCheckAndConvert:self];
}


- (IBAction)convertLossy:(id)aSender {
    [O_foundErrors setContent:[NSMutableArray array]];
    NSArray *selectionOperationArray=[(TextStorage *)[I_document textStorage] selectionOperationsForRangesUnconvertableToEncoding:I_encoding];
    int i = [selectionOperationArray count];
    [[I_document documentUndoManager] beginUndoGrouping];
    TextStorage *textStorage = (TextStorage *)[I_document textStorage];
    [textStorage beginEditing];
    NSString *string=[textStorage string];
    NSDictionary *attributes = [I_document typingAttributes];
    while (--i>=0) {
        NSRange range = [[selectionOperationArray objectAtIndex:i] selectedRange];
        NSData *lossyData = [[string substringWithRange:range] dataUsingEncoding:I_encoding allowLossyConversion:YES];
        NSString *replacementString = [[NSString alloc] initWithData:lossyData encoding:I_encoding];
        [textStorage replaceCharactersInRange:range withString:replacementString];
        [textStorage setAttributes:attributes range:NSMakeRange(range.location, [replacementString length])];
        [replacementString release];
    }
    [I_document setFileEncodingUndoable:I_encoding];
    [textStorage endEditing];
    [[I_document documentUndoManager] endUndoGrouping];
    [self orderOut:self];
}

- (IBAction)rerunCheckAndConvert:(id)aSender {
    [O_foundErrors setContent:[NSMutableArray array]];
    NSMutableArray *newErrors=[NSMutableArray array];
    NSArray *selectionOperationArray=[(TextStorage *)[I_document textStorage] selectionOperationsForRangesUnconvertableToEncoding:I_encoding];
    NSEnumerator *selectionOperations=[selectionOperationArray objectEnumerator];
    SelectionOperation *selectionOperation = nil;
    TextStorage *textStorage = (TextStorage *)[I_document textStorage];
    NSString *string=[textStorage string];
    NSRange currentLineRange=[string lineRangeForRange:NSMakeRange(0,0)];
    int currentLineNumber = 1;
    NSColor *highlightColor = [[NSColor yellowColor] highlightWithLevel:0.5];
    while ((selectionOperation=[selectionOperations nextObject])) {
        NSMutableDictionary *dictionary=[NSMutableDictionary dictionaryWithObject:selectionOperation forKey:@"selectionOperation"];
        NSRange errorRange=[selectionOperation selectedRange];
        NSRange lineRange = [string lineRangeForRange:errorRange];
        if (!NSEqualRanges(currentLineRange, lineRange)) {
            currentLineRange = lineRange;
            currentLineNumber = [textStorage lineNumberForLocation:lineRange.location];
        }
        [dictionary setObject:[NSNumber numberWithInt:currentLineNumber] forKey:@"line"];
        BOOL truncStart = NO;
        BOOL truncEnd = NO;
        if (errorRange.location - lineRange.location>10) {
            int difference = errorRange.location - lineRange.location - 10;
            lineRange.location += difference;
            lineRange.length   -= difference;
            truncStart = YES;
        }
        if (NSMaxRange(lineRange) > NSMaxRange(errorRange) + 10) {
            lineRange.length = (NSMaxRange(errorRange) + 10) - lineRange.location;
            truncEnd = YES;
        }
        NSMutableAttributedString *attString = [[[NSMutableAttributedString alloc] initWithString:[string substringWithRange:lineRange]] autorelease];
        NSRange highlightRange = NSMakeRange(errorRange.location - lineRange.location, errorRange.length);
        [attString addAttribute:NSBackgroundColorAttributeName value:highlightColor       range:highlightRange];
        [attString addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:highlightRange];
        if (truncStart) [attString replaceCharactersInRange:NSMakeRange(0,0) withString:@"..."];
        if (truncEnd)   [attString replaceCharactersInRange:NSMakeRange([attString length],0) withString:@"..."];
    
        [dictionary setObject:attString forKey:@"errorString"];
        [newErrors addObject:dictionary];
    }
    [O_foundErrors setContent:newErrors];

    if ([[O_foundErrors arrangedObjects] count]>0) {
        [O_foundErrors setSelectionIndex:0];
        [self jumpToSelection:self];
        [[O_tableView window] makeFirstResponder:O_tableView];
        [O_convertButton setEnabled:NO];
    } else {
        [I_document setFileEncodingUndoable:I_encoding];
        [I_document updateChangeCount:NSChangeDone];
        [self orderOut:self];
    }
}

- (NSArray *)arrangedObjects {
    return [O_foundErrors arrangedObjects];
}

- (void)jumpToSelection:(id)sender {
    if(I_document) {
        NSRange range = [[[[O_foundErrors selectedObjects] lastObject] objectForKey:@"selectionOperation"] selectedRange];
        if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)) {
            [I_document newView:self];
        }
        [I_document selectRange:range];
    } 
}

- (void)jumpToSelectionAndBecomeKey:(id)sender {
    [self jumpToSelection:sender];
    if(I_document) {
        PlainTextWindowController *wc=[I_document topmostWindowController];
        [[wc window] makeFirstResponder:[[wc activePlainTextEditor] textView]]; 
    } 
}


- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex {
	NSRange range = [[[[O_foundErrors arrangedObjects] objectAtIndex:rowIndex] objectForKey:@"selectionOperation"] selectedRange];
	[I_document selectRangeInBackground:range];
	return YES;
}

- (IBAction)cancel:(id)aSender {
    [self orderOut:self];
}

- (id)initialFirstResponder {
    return O_tableView;
}

- (void)takeNoteOfOperation:(TCMMMOperation *)anOperation transformator:(TCMMMTransformator *)aTransformator {
    NSEnumerator *operations = [[O_foundErrors arrangedObjects] objectEnumerator];
    NSDictionary *dictionary = nil;
    while ((dictionary = [operations nextObject])) {
        [aTransformator transformOperation:[dictionary objectForKey:@"selectionOperation"] 
                           serverOperation:anOperation];
    }
    if (![O_convertButton isEnabled]) [O_convertButton setEnabled:YES];
}

@end
