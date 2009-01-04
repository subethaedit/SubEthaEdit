/*
        LinePanelController.m
        Copyright (c) 2007 by Apple Computer, Inc., all rights reserved.
        Author: Ali Ozer

        "Select Line" panel controller for TextEdit. 
	Enables selecting a single line, range of lines, from start or relative to current selected range.
*/
/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple's copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


#import "LinePanelController.h"
#import "TextEditErrors.h"


@implementation LinePanelController

- (id)init {
    return [super initWithWindowNibName:@"SelectLinePanel"];
}

/* A short and sweet example of use of NSScanner. Parses user's line specification, in the form of N, or N-M, or +N-M, or -N-M. Returns NO on error. Assumes none of the out parameters are NULL!
*/
- (BOOL)parseLineDescription:(NSString *)desc fromLineSpec:(NSInteger *)fromLine toLineSpec:(NSInteger *)toLine relative:(NSInteger *)relative {
    NSScanner *scanner = [NSScanner localizedScannerWithString:desc];
    *relative = [scanner scanString:@"+" intoString:NULL] ? 1 : ([scanner scanString:@"-" intoString:NULL] ? -1 : 0);	    // Look for "+" or "-"; set relative to 1 or -1, or 0 if neither found
    if (![scanner scanInteger:fromLine]) return NO;	// Get the "from" spec
    if ([scanner scanString:@"-" intoString:NULL]) {	// If "-" seen, look for the "to" spec
	if (![scanner scanInteger:toLine] || (*toLine < *fromLine)) return NO;	    // There needs to be a number that is not less than the "from" spec
    } else {
	*toLine = *fromLine;				// If not a range, set the "to" spec to be the same as "from"
    }
    return [scanner isAtEnd] ? YES : NO;		// If more stuff, error. Note that the scanner skips over white space
}

/* getRange:... gets the range to be selected in the specified textView using the indicated start, end, and relative values
    If relative = 0, then select from start of fromLine to end of toLine. The first line of the text is line 1.
    If relative != 0 then select from start of fromLine lines from current selected range to toLine lines from current selected range.
      toLine == fromLine means a one-line selection
*/
- (BOOL)getRange:(NSRange *)rangePtr inTextView:(NSTextView *)textView fromLineSpec:(NSInteger)fromLine toLineSpec:(NSInteger)toLine relative:(NSInteger)relative {
    NSRange newSelection = {0, 0};	// Character locations for the new selection
    NSString *textString = [textView string];

    if (relative != 0) {		// Depending on relative direction, set the starting point to beginning of line at the start or end of the existing selected range
	NSRange curSel = [textView selectedRange];
	if (relative > 0) curSel.location = NSMaxRange(curSel) - ((curSel.length > 0) ? 1 : 0);
	[textString getLineStart:&newSelection.location end:NULL contentsEnd:NULL forRange:NSMakeRange(curSel.location, 0)];
    } else {
	if (fromLine == 0) return NO;	// "0" is not a valid absolute line spec
    }

    // At this point, newSelection.location points at the beginning of the line we want to start from
    if (relative < 0) {	    // Backwards relative from that spot
	for (NSInteger cnt = 1; cnt < fromLine; cnt++) {
	    if (newSelection.location == 0) return NO;	// Invalid specification
	    NSRange lineRange = [textString lineRangeForRange:NSMakeRange(newSelection.location - 1, 0)];
	    newSelection.location = lineRange.location;
	}
	NSInteger end = newSelection.location;	// This now marks the end of the range to be selected
	for (NSInteger cnt = fromLine; cnt <= toLine; cnt++) {
	    if (newSelection.location == 0) return NO;	// Invalid specification
	    NSRange lineRange = [textString lineRangeForRange:NSMakeRange(newSelection.location - 1, 0)];
	    newSelection.location = lineRange.location;
	}
	newSelection.length = end - newSelection.location;
    } else {		    // Forwards
	NSInteger textLength = [textString length];
	for (NSInteger cnt = (relative == 0) ? 1 : 0; cnt < fromLine; cnt++) {	// If not a relative selection, we start counting from 1, since the first line is "line 1" to the user
	    if (newSelection.location == textLength) return NO;	    // Invalid specification
	    NSRange lineRange = [textString lineRangeForRange:NSMakeRange(newSelection.location, 0)];
	    newSelection.location = NSMaxRange(lineRange);
	}
	NSInteger end = newSelection.location;
	for (NSInteger cnt = fromLine; cnt <= toLine; cnt++) {	// If not relative, the end of the range is an absolute line number; otherwise it's relative
	    if (end == textLength) return NO;    // Invalid specification
	    NSRange lineRange = [textString lineRangeForRange:NSMakeRange(end, 0)];
	    end = NSMaxRange(lineRange);
	}
	newSelection.length = end - newSelection.location;
    }
    if (rangePtr) *rangePtr = newSelection;
    return YES;
}

/* selectLinesUsingDescription:error: selects the specified lines. On error it returns NO and sets *error if not NULL.
*/
- (BOOL)selectLinesUsingDescription:(NSString *)desc error:(NSError **)error {
    id firstResponder = [[NSApp mainWindow] firstResponder];
    if ([firstResponder isKindOfClass:[NSTextView class]]) {
	NSInteger fromLine, toLine, relative;
	if (![self parseLineDescription:desc fromLineSpec:&fromLine toLineSpec:&toLine relative:&relative]) {
	    if (error) *error = [NSError errorWithDomain:TextEditErrorDomain code:TextEditInvalidLineSpecification userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Invalid line specification \\U201c%@\\U201d.", @"LinePanel", @"Error message indicating invalid line specification for 'Select Line'"), desc], NSLocalizedDescriptionKey, NSLocalizedStringFromTable(@"Please enter the line number or numbers (separated by dash) of the line(s) to select.", @"LinePanel", @"Suggestion for correcting invalid line specification"), NSLocalizedRecoverySuggestionErrorKey, nil]];
	    return NO;
	}
	NSRange range;
        if (![self getRange:&range inTextView:firstResponder fromLineSpec:fromLine toLineSpec:toLine relative:relative]) {
	    if (error) *error = [NSError errorWithDomain:TextEditErrorDomain code:TextEditOutOfRangeLineSpecification userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Out of bounds line specification \\U201c%@\\U201d.", @"LinePanel", @"Error message indicating out of bounds line specification for 'Select Line'"), desc], NSLocalizedDescriptionKey, nil]];
	    return NO;
	}
	[firstResponder setSelectedRange:range];
	[firstResponder scrollRangeToVisible:range];
    }
    return YES;
}

/* If the user enters a line specification and hits return, we want to order the panel out if successful.  Hence this extra action method.
*/
- (IBAction)lineFieldChanged:(id)sender {
    NSError *error;
    if ([@"" isEqual:[sender stringValue]]) return;	// Don't do anything on empty string
    if ([self selectLinesUsingDescription:[sender stringValue] error:&error]) {
	[[self window] orderOut:nil];
    } else {
	[[self window] presentError:error];
	[[self window] makeKeyAndOrderFront:nil];
    }
}

/* Default action for the "Select" button.
*/
- (IBAction)selectClicked:(id)sender {
    NSError *error;
    if ([@"" isEqual:[lineField stringValue]]) return;	// Don't do anything on empty string
    if (![self selectLinesUsingDescription:[lineField stringValue] error:&error]) {
	[[self window] presentError:error];
	[[self window] makeKeyAndOrderFront:nil];
    }
}

@end
