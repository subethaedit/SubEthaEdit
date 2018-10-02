//  EncodingDoctorDialog.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 11.09.06.

#import "SEEEncodingDoctorDialogViewController.h"
#import "SelectionOperation.h"
#import "FoldableTextStorage.h"
#import "PlainTextDocument.h"
#import "PlainTextWindowController.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@interface SEEEncodingDoctorDialogViewController()
@property (nonatomic, strong) IBOutlet NSButton *cancelButton;
@property (nonatomic, strong) IBOutlet NSButton *convertButton;
@property (nonatomic, strong) IBOutlet NSButton *convertLossyButton;
@property (nonatomic, strong) IBOutlet NSArrayController *foundErrorsArrayController;
@property (nonatomic, strong) IBOutlet NSTextField *descriptionTextField;
@property (nonatomic, strong) IBOutlet NSTableView *tableView;

@property (nonatomic, readonly) PlainTextDocument *document;
@end

@implementation SEEEncodingDoctorDialogViewController
@synthesize tabContext = _tabContext;

- (id)initWithEncoding:(NSStringEncoding)anEncoding {
    if ((self=[super initWithNibName:@"SEEEncodingDoctorView" bundle:nil])) {
		self.encoding = anEncoding;
    }
    return self;
}

- (void)loadView {
	[super loadView];
	NSTableView *tableView = self.tableView;
    [tableView setTarget: self];
    [tableView setAction:@selector(jumpToSelection:)];
    [tableView setDoubleAction:@selector(jumpToSelectionAndBecomeKey:)];
    [self.descriptionTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"ENCODING_DOCTOR_HEADLINE", @""),[NSString localizedNameOfStringEncoding:self.encoding]]];
	[self.cancelButton setTitle:NSLocalizedString(@"ENCODING_DOCTOR_CANCEL", @"")];
	[self.convertLossyButton setTitle:NSLocalizedString(@"ENCODING_DOCTOR_CONVERT_LOSSY", @"")];
	[self.convertButton setTitle:NSLocalizedString(@"ENCODING_DOCTOR_CONVERT", @"")];
	
	[[[tableView tableColumns][0] headerCell] setStringValue:NSLocalizedString(@"ENCODING_DOCTOR_TABLEHEADING_LINE", @"")];
	[[[tableView tableColumns][1] headerCell] setStringValue:NSLocalizedString(@"ENCODING_DOCTOR_TABLEHEADING_ERROR", @"")];
	
    [self rerunCheckAndConvert:self];
}

- (PlainTextDocument *)document {
	PlainTextDocument *result = self.tabContext.document;
	return result;
}

- (IBAction)convertLossy:(id)aSender {
	PlainTextDocument *document = self.document;
    [self.foundErrorsArrayController setContent:[NSMutableArray array]];
    NSArray *selectionOperationArray=[(FoldableTextStorage *)[document textStorage] selectionOperationsForRangesUnconvertableToEncoding:self.encoding];
    int i = [selectionOperationArray count];
    [[document documentUndoManager] beginUndoGrouping];
    FullTextStorage *textStorage = [(FoldableTextStorage *)[document textStorage] fullTextStorage];
    [textStorage beginEditing];
    NSString *string=[textStorage string];
    NSDictionary *attributes = [document typingAttributes];
    while (--i>=0) {
        NSRange range = [[selectionOperationArray objectAtIndex:i] selectedRange];
        NSData *lossyData = [[string substringWithRange:range] dataUsingEncoding:self.encoding allowLossyConversion:YES];
        NSString *replacementString = [[NSString alloc] initWithData:lossyData encoding:self.encoding];
        [textStorage replaceCharactersInRange:range withString:replacementString];
        [textStorage setAttributes:attributes range:NSMakeRange(range.location, [replacementString length])];
    }
    [document setFileEncodingUndoable:self.encoding];
    [textStorage endEditing];
    [[document documentUndoManager] endUndoGrouping];
    [self orderOut:self];
}

- (void)orderOut:(id)aSender {
	[self.tabContext setDocumentDialog:nil];
}

- (IBAction)rerunCheckAndConvert:(id)aSender {
	PlainTextDocument *document = self.document;

    [self.foundErrorsArrayController setContent:[NSMutableArray array]];
    NSMutableArray *newErrors=[NSMutableArray array];
    NSArray *selectionOperationArray=[(FoldableTextStorage *)[document textStorage] selectionOperationsForRangesUnconvertableToEncoding:self.encoding];
    SelectionOperation *selectionOperation = nil;
    FullTextStorage *textStorage = [(FoldableTextStorage *)[document textStorage] fullTextStorage];
    NSString *string=[textStorage string];
    NSRange currentLineRange=[string lineRangeForRange:NSMakeRange(0,0)];
    int currentLineNumber = 1;
    NSColor *highlightColor = [[NSColor yellowColor] highlightWithLevel:0.5];
    for (selectionOperation in selectionOperationArray) {
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
        NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:[string substringWithRange:lineRange]];
        NSRange highlightRange = NSMakeRange(errorRange.location - lineRange.location, errorRange.length);
        [attString addAttribute:NSBackgroundColorAttributeName value:highlightColor       range:highlightRange];
        [attString addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:highlightRange];
        if (truncStart) [attString replaceCharactersInRange:NSMakeRange(0,0) withString:@"..."];
        if (truncEnd)   [attString replaceCharactersInRange:NSMakeRange([attString length],0) withString:@"..."];
    
        [dictionary setObject:attString forKey:@"errorString"];
        [newErrors addObject:dictionary];
    }
    [self.foundErrorsArrayController setContent:newErrors];

    if ([(NSArray*)[self.foundErrorsArrayController arrangedObjects] count]>0) {
        [self.foundErrorsArrayController setSelectionIndex:0];
        [self jumpToSelection:self];
        [[self.tableView window] makeFirstResponder:self.tableView];
        [self.convertButton setEnabled:NO];
    } else {
        [document setFileEncodingUndoable:self.encoding];
        [document updateChangeCount:NSChangeDone];
        [self orderOut:self];
    }
}

- (NSArray *)arrangedObjects {
    return [self.foundErrorsArrayController arrangedObjects];
}

- (void)jumpToSelection:(id)sender {
	PlainTextDocument *document = self.document;

    if(document) {
        NSRange range = [[[[self.foundErrorsArrayController selectedObjects] lastObject] objectForKey:@"selectionOperation"] selectedRange];
        if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)) {
            [document newView:self];
        }
        [document selectRange:range];
    }
}

- (void)jumpToSelectionAndBecomeKey:(id)sender {
 	PlainTextDocument *document = self.document;
	[self jumpToSelection:sender];
    if(document) {
        PlainTextWindowController *wc=[document topmostWindowController];
        [[wc window] makeFirstResponder:[[wc activePlainTextEditor] textView]];
    }
}


- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
	PlainTextDocument *document = self.document;
	NSRange range = [[[[self.foundErrorsArrayController arrangedObjects] objectAtIndex:rowIndex] objectForKey:@"selectionOperation"] selectedRange];
	[document selectRangeInBackground:range];
	return YES;
}

- (IBAction)cancel:(id)aSender {
    [self orderOut:self];
}

- (id)initialFirstResponder {
    return self.tableView;
}

- (void)takeNoteOfOperation:(TCMMMOperation *)anOperation transformator:(TCMMMTransformator *)aTransformator {
    NSEnumerator *operations = [[self.foundErrorsArrayController arrangedObjects] objectEnumerator];
    NSDictionary *dictionary = nil;
    while ((dictionary = [operations nextObject])) {
        [aTransformator transformOperation:[dictionary objectForKey:@"selectionOperation"] 
                           serverOperation:anOperation];
    }
    if (![self.convertButton isEnabled]) [self.convertButton setEnabled:YES];
}

@end
