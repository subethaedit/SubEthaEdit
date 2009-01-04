/*
        DocumentWindowController.m
        Copyright (c) 1995-2007 by Apple Computer, Inc., all rights reserved.
        Author: David Remahl, adapted from old Document.m
 
        Document's main window controller object for TextEdit
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

#import "DocumentWindowController.h"
#import "Document.h"
#import "MultiplePageView.h"
#import "Preferences.h"
#import "TextView.h"

@interface DocumentWindowController(Private)

- (void)setDocument:(Document *)doc; // Overridden with more specific type. Expects Document instance.

- (void)setupInitialTextViewSharedState;
- (void)setupTextViewForDocument;
- (void)setupWindowForDocument;
- (void)updateForRichTextAndRulerState;

- (void)showRulerDelayed:(BOOL)flag;

- (void)addPage;
- (void)removePage;

- (NSTextView *)firstTextView;

- (void)printInfoUpdated;

- (void)resizeWindowForViewSize:(NSSize)size;
- (void)setHasMultiplePages:(BOOL)pages force:(BOOL)force;

@end


@implementation DocumentWindowController

- (id)init {
    if (self = [super initWithWindowNibName:@"DocumentWindow"]) {
	layoutMgr = [[NSLayoutManager allocWithZone:[self zone]] init];
	[layoutMgr setDelegate:self];
	[layoutMgr setAllowsNonContiguousLayout:YES];
    }
    return self;
}

- (void)dealloc {
    if ([self document]) [self setDocument:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[self firstTextView] removeObserver:self forKeyPath:@"backgroundColor"];
    [scrollView removeObserver:self forKeyPath:@"scaleFactor"];
    
    [layoutMgr release];
    
    [self showRulerDelayed:NO];
    
    [super dealloc]; // NSWindowController deallocates all the nib objects
}

/* This method can be called in three different situations (number three is a special TextEdit case):
	1) When the window controller is created and set up with a new or opened document. (!oldDoc && doc)
	2) When the document is closed, and the controller is about to be destroyed (oldDoc && !doc)
	3) When the window controller is assigned to another document (a document has been opened
	    and it takes the place of an automatically-created window). (oldDoc && doc)

   The window can be visible or hidden at the time of the message.
*/
- (void)setDocument:(Document *)doc {
    Document *oldDoc = [[self document] retain];
    
    if (oldDoc) {
        [layoutMgr unbind:@"hyphenationFactor"];
        [[self firstTextView] unbind:@"editable"];
    }
    [super setDocument:doc];
    if (doc) {
        [layoutMgr bind:@"hyphenationFactor" toObject:self withKeyPath:@"document.hyphenationFactor" options:nil];
        [[self firstTextView] bind:@"editable" toObject:self withKeyPath:@"document.readOnly" options:[NSDictionary dictionaryWithObject:NSNegateBooleanTransformerName forKey:NSValueTransformerNameBindingOption]];
    }
    if (oldDoc != doc) {
	if (oldDoc) {
	    /* Remove layout manager from the old Document's text storage. No need to retain as we already own the object. */
	    [[oldDoc textStorage] removeLayoutManager:layoutMgr];
	    
	    [oldDoc removeObserver:self forKeyPath:@"printInfo"];
	    [oldDoc removeObserver:self forKeyPath:@"richText"];
            [oldDoc removeObserver:self forKeyPath:@"viewSize"];
	    [oldDoc removeObserver:self forKeyPath:@"hasMultiplePages"];
	}
	
	if (doc) {
            [[doc textStorage] addLayoutManager:layoutMgr];
	    
	    if ([self isWindowLoaded]) {
                [self setHasMultiplePages:[doc hasMultiplePages] force:NO];
                [self setupInitialTextViewSharedState];
                [self setupWindowForDocument];
		if ([doc hasMultiplePages]) [scrollView setScaleFactor:[[self document] scaleFactor] adjustPopup:YES];
                [[doc undoManager] removeAllActions];
            }
	    
	    [doc addObserver:self forKeyPath:@"printInfo" options:0 context:NULL];
	    [doc addObserver:self forKeyPath:@"richText" options:0 context:NULL];
	    [doc addObserver:self forKeyPath:@"viewSize" options:0 context:NULL];
	    [doc addObserver:self forKeyPath:@"hasMultiplePages" options:0 context:NULL];
	}
    }
    
    [oldDoc release];
}

- (void)breakUndoCoalescing {
    [[self firstTextView] breakUndoCoalescing];
}

- (NSLayoutManager *)layoutManager {
    return layoutMgr;
}

- (NSTextView *)firstTextView {
    return [[self layoutManager] firstTextView];
}

- (void)setupInitialTextViewSharedState {
    NSTextView *textView = [self firstTextView];
    
    [textView setUsesFontPanel:YES];
    [textView setUsesFindPanel:YES];
    [textView setDelegate:self];
    [textView setAllowsUndo:YES];
    [textView setAllowsDocumentBackgroundColorChange:YES];
    [textView setContinuousSpellCheckingEnabled:[[Preferences objectForKey:CheckSpellingAsYouType] boolValue]];
    [textView setGrammarCheckingEnabled:[[Preferences objectForKey:CheckGrammarWithSpelling] boolValue]];
    [textView setSmartInsertDeleteEnabled:[[Preferences objectForKey:SmartCopyPaste] boolValue]];
    [textView setAutomaticQuoteSubstitutionEnabled:[[Preferences objectForKey:SmartQuotes] boolValue]];
    [textView setAutomaticLinkDetectionEnabled:[[Preferences objectForKey:SmartLinks] boolValue]];
    [textView setSelectedRange:NSMakeRange(0, 0)];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [self firstTextView]) {
	if ([keyPath isEqualToString:@"backgroundColor"]) {
	    [[self document] setBackgroundColor:[[self firstTextView] backgroundColor]];
	} 
    } else if (object == scrollView) {
	if ([keyPath isEqualToString:@"scaleFactor"]) {
	    [[self document] setScaleFactor:[scrollView scaleFactor]];
	} 
    } else if (object == [self document]) {
	if ([keyPath isEqualToString:@"printInfo"]) {
	    [self printInfoUpdated];
	} else if ([keyPath isEqualToString:@"richText"]) {
            if ([self isWindowLoaded]) {
                [self updateForRichTextAndRulerState];
            }
	} else if ([keyPath isEqualToString:@"viewSize"]) {
	    if (!isSettingSize) {
		NSSize size = [[self document] viewSize];
		if (!NSEqualSizes(size, NSZeroSize)) {
		    [self resizeWindowForViewSize:size];
		}
	    }
	} else if ([keyPath isEqualToString:@"hasMultiplePages"]) {
	    [self setHasMultiplePages:[[self document] hasMultiplePages] force:NO];
	}
    }
}

- (void)setupTextViewForDocument {
    Document *doc = [self document];
    BOOL rich = [doc isRichText];
    
    if (doc && (!rich || [[[self firstTextView] textStorage] length] == 0)) [[self firstTextView] setTypingAttributes:[doc defaultTextAttributes:rich]];
    [self updateForRichTextAndRulerState];
    
    [[self firstTextView] setBackgroundColor:[doc backgroundColor]];
}

- (void)printInfoUpdated {
    if (hasMultiplePages) {
        NSUInteger cnt, numberOfPages = [self numberOfPages];
        MultiplePageView *pagesView = [scrollView documentView];
        NSArray *textContainers = [[self layoutManager] textContainers];
	
        [pagesView setPrintInfo:[[self document] printInfo]];
        
        for (cnt = 0; cnt < numberOfPages; cnt++) {
            NSRect textFrame = [pagesView documentRectForPageNumber:cnt];
            NSTextContainer *textContainer = [textContainers objectAtIndex:cnt];
            [textContainer setContainerSize:textFrame.size];
            [[textContainer textView] setFrame:textFrame];
        }
    }
}

/* Method to lazily display ruler. Call with YES to display, NO to cancel display; this method doesn't remove the ruler. 
*/
- (void)showRulerDelayed:(BOOL)flag {
    if (!flag && rulerIsBeingDisplayed) {
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(showRuler:) object:self];
    } else if (flag && !rulerIsBeingDisplayed) {
        [self performSelector:@selector(showRuler:) withObject:self afterDelay:0.0];
    }
    rulerIsBeingDisplayed = flag;
}

- (void)showRuler:(id)obj {
    if (rulerIsBeingDisplayed && !obj) [self showRulerDelayed:NO];	// Cancel outstanding request, if not coming from the delayed request
    if ([[Preferences objectForKey:ShowRuler] boolValue]) [[self firstTextView] setRulerVisible:YES];
}

/* Used when converting to plain text
*/
- (void)removeAttachments {
    NSTextStorage *attrString = [[self document] textStorage];
    NSTextView *view = [self firstTextView];
    NSUInteger loc = 0;
    NSUInteger end = [attrString length];
    [attrString beginEditing];
    while (loc < end) {	/* Run through the string in terms of attachment runs */
        NSRange attachmentRange;	/* Attachment attribute run */
        NSTextAttachment *attachment = [attrString attribute:NSAttachmentAttributeName atIndex:loc longestEffectiveRange:&attachmentRange inRange:NSMakeRange(loc, end-loc)];
        if (attachment != nil) {	/* If there is an attachment, make sure it is valid */
            unichar ch = [[attrString string] characterAtIndex:loc];
            if (ch == NSAttachmentCharacter) {
		if ([view shouldChangeTextInRange:NSMakeRange(loc, 1) replacementString:@""]) {
		    [attrString replaceCharactersInRange:NSMakeRange(loc, 1) withString:@""];
		    [view didChangeText];
		}
                end = [attrString length];	/* New length */
            }
	    else loc++;	/* Just skip over the current character... */
        }
    	else loc = NSMaxRange(attachmentRange);
    }
    [attrString endEditing];
}

/* Doesn't check to see if the prev value is the same --- Otherwise the first time doesn't work...
attachmentFlag allows for optimizing some cases where we know we have no attachments, so we don't need to scan looking for them.
*/
- (void)updateForRichTextAndRulerState {
    NSTextView *view = [self firstTextView];
    BOOL rich = [[self document] isRichText];
    
    [view setRichText:rich];
    [view setUsesRuler:rich];	// If NO, this correctly gets rid of the ruler if it was up
    if (!rich && rulerIsBeingDisplayed) [self showRulerDelayed:NO];	// Cancel delayed ruler request
    if (rich && ![[self document] isReadOnly]) [self showRulerDelayed:YES];
    [view setImportsGraphics:rich];
}

- (void)convertTextForRichTextStateRemoveAttachments:(BOOL)attachmentFlag {
    NSTextView *view = [self firstTextView];
    Document *doc = [self document];
    BOOL rich = [doc isRichText];
    NSDictionary *textAttributes = [doc defaultTextAttributes:rich];
    NSParagraphStyle *paragraphStyle = [textAttributes objectForKey:NSParagraphStyleAttributeName];
    
    // Note, since the textview content changes (removing attachments and changing attributes) create undo actions inside the textview, we do not execute them here if we're undoing or redoing
    if (![[doc undoManager] isUndoing] && ![[doc undoManager] isRedoing]) {
	NSTextStorage *textStorage = [[self document] textStorage];
	if (!rich && attachmentFlag) [self removeAttachments];
	NSRange range = NSMakeRange(0, [textStorage length]);
        if ([view shouldChangeTextInRange:range replacementString:nil]) {
	    [textStorage setAttributes:textAttributes range: range];
	    [view didChangeText];
	}
    }
    [view setTypingAttributes:textAttributes];
    [view setDefaultParagraphStyle:paragraphStyle];
}

- (NSUInteger)numberOfPages {
    return hasMultiplePages ? [[scrollView documentView] numberOfPages] : 1;
}

- (void)addPage {
    NSZone *zone = [self zone];
    NSUInteger numberOfPages = [self numberOfPages];
    MultiplePageView *pagesView = [scrollView documentView];
    
    NSSize textSize = [pagesView documentSizeInPage];
    NSTextContainer *textContainer = [[NSTextContainer allocWithZone:zone] initWithContainerSize:textSize];
    NSTextView *textView;
    [pagesView setNumberOfPages:numberOfPages + 1];
    textView = [[TextView allocWithZone:zone] initWithFrame:[pagesView documentRectForPageNumber:numberOfPages] textContainer:textContainer];
    [textView setHorizontallyResizable:NO];
    [textView setVerticallyResizable:NO];
    [pagesView addSubview:textView];
    [[self layoutManager] addTextContainer:textContainer];
    [textView release];
    [textContainer release];
}

- (void)removePage {
    NSUInteger numberOfPages = [self numberOfPages];
    NSArray *textContainers = [[self layoutManager] textContainers];
    NSTextContainer *lastContainer = [textContainers objectAtIndex:[textContainers count] - 1];
    MultiplePageView *pagesView = [scrollView documentView];
    
    [pagesView setNumberOfPages:numberOfPages - 1];
    [[lastContainer textView] removeFromSuperview];
    [[lastContainer layoutManager] removeTextContainerAtIndex:[textContainers count] - 1];
}

- (NSView *)documentView {
    return [scrollView documentView];
}

- (void)setHasMultiplePages:(BOOL)pages force:(BOOL)force {
    NSZone *zone = [self zone];
    
    if (!force && (hasMultiplePages == pages)) return;
    
    hasMultiplePages = pages;
    
    [[self firstTextView] removeObserver:self forKeyPath:@"backgroundColor"];
    [[self firstTextView] unbind:@"editable"];
    
    if (hasMultiplePages) {
        NSTextView *textView = [self firstTextView];
        MultiplePageView *pagesView = [[MultiplePageView allocWithZone:zone] init];
	
        [scrollView setDocumentView:pagesView];
	
        [pagesView setPrintInfo:[[self document] printInfo]];
        // Add the first new page before we remove the old container so we can avoid losing all the shared text view state.
        [self addPage];
        if (textView) {
            [[self layoutManager] removeTextContainerAtIndex:0];
        }
        [scrollView setHasHorizontalScroller:YES];
	
        // Make sure the selected text is shown
        [[self firstTextView] scrollRangeToVisible:[[self firstTextView] selectedRange]];
	
        NSRect visRect = [pagesView visibleRect];
	NSRect pageRect = [pagesView pageRectForPageNumber:0];
        if (visRect.size.width < pageRect.size.width) {	// If we can't show the whole page, tweak a little further
            NSRect docRect = [pagesView documentRectForPageNumber:0];
            if (visRect.size.width >= docRect.size.width) {	// Center document area in window
                visRect.origin.x = docRect.origin.x - floor((visRect.size.width - docRect.size.width) / 2);
                if (visRect.origin.x < pageRect.origin.x) visRect.origin.x = pageRect.origin.x;
            } else {	// If we can't show the document area, then show left edge of document area (w/out margins)
                visRect.origin.x = docRect.origin.x;
            }
            [pagesView scrollRectToVisible:visRect];
        }
        [pagesView release];
    } else {
        NSSize size = [scrollView contentSize];
        NSTextContainer *textContainer = [[NSTextContainer allocWithZone:zone] initWithContainerSize:NSMakeSize(size.width, CGFLOAT_MAX)];
        NSTextView *textView = [[TextView allocWithZone:zone] initWithFrame:NSMakeRect(0.0, 0.0, size.width, size.height) textContainer:textContainer];
	
        // Insert the single container as the first container in the layout manager before removing the existing pages in order to preserve the shared view state.
        [[self layoutManager] insertTextContainer:textContainer atIndex:0];
	
        if ([[scrollView documentView] isKindOfClass:[MultiplePageView class]]) {
            NSArray *textContainers = [[self layoutManager] textContainers];
            NSUInteger cnt = [textContainers count];
            while (cnt-- > 1) {
                [[self layoutManager] removeTextContainerAtIndex:cnt];
            }
        }
	
        [textContainer setWidthTracksTextView:YES];
        [textContainer setHeightTracksTextView:NO];		/* Not really necessary */
        [textView setHorizontallyResizable:NO];			/* Not really necessary */
        [textView setVerticallyResizable:YES];
	[textView setAutoresizingMask:NSViewWidthSizable];
        [textView setMinSize:size];	/* Not really necessary; will be adjusted by the autoresizing... */
        [textView setMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];	/* Will be adjusted by the autoresizing... */  
	
        /* The next line should cause the multiple page view and everything else to go away */
        [scrollView setDocumentView:textView];
        [scrollView setHasHorizontalScroller:NO];
        
        [textView release];
        [textContainer release];
	
        // Show the selected region
        [[self firstTextView] scrollRangeToVisible:[[self firstTextView] selectedRange]];
    }
    
    [[self firstTextView] addObserver:self forKeyPath:@"backgroundColor" options:0 context:NULL];
    [[self firstTextView] bind:@"editable" toObject:self withKeyPath:@"document.readOnly" options:[NSDictionary dictionaryWithObject:NSNegateBooleanTransformerName forKey:NSValueTransformerNameBindingOption]];
    
    [[scrollView window] makeFirstResponder:[self firstTextView]];
    [[scrollView window] setInitialFirstResponder:[self firstTextView]];	// So focus won't be stolen (2934918)
}

- (void)resizeWindowForViewSize:(NSSize)size {
    NSWindow *window = [self window];
    NSRect origWindowFrame = [window frame];
    if (![[self document] hasMultiplePages]) {
	size.width += (defaultTextPadding() * 2.0);
    }
    NSRect scrollViewRect = [[window contentView] frame];
    scrollViewRect.size = [[scrollView class] frameSizeForContentSize:size hasHorizontalScroller:[scrollView hasHorizontalScroller] hasVerticalScroller:[scrollView hasVerticalScroller] borderType:[scrollView borderType]];
    NSRect newFrame = [window frameRectForContentRect:scrollViewRect];
    newFrame.origin = NSMakePoint(origWindowFrame.origin.x, NSMaxY(origWindowFrame) - newFrame.size.height);
    [window setFrame:newFrame display:YES];
}

- (void)setupWindowForDocument {
    NSSize viewSize = [[self document] viewSize];
    [self setupTextViewForDocument];
    
    if (!NSEqualSizes(viewSize, NSZeroSize)) { // Document has a custom view size that should be used
	[self resizeWindowForViewSize:viewSize];
    } else { // Set the window size from defaults...
	if (hasMultiplePages) {
	    [self resizeWindowForViewSize:[[scrollView documentView] pageRectForPageNumber:0].size];
	} else {
	    NSInteger windowHeight = [[Preferences objectForKey:WindowHeight] integerValue];
	    NSInteger windowWidth = [[Preferences objectForKey:WindowWidth] integerValue];
	    NSFont *font = [Preferences objectForKey:[[self document] isRichText] ? RichTextFont : PlainTextFont];
            NSSize size;
            size.height = ceil([[self layoutManager] defaultLineHeightForFont:font] * windowHeight);
            size.width = [@"x" sizeWithAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]].width;
            if (size.width == 0.0) size.width = [@" " sizeWithAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]].width; /* try for space width */
            if (size.width == 0.0) size.width = [font maximumAdvancement].width; /* or max width */
	    size.width  = ceil(size.width * windowWidth);
	    [self resizeWindowForViewSize:size];
	}
    }
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // This creates the first text view
    [self setHasMultiplePages:[[self document] hasMultiplePages] force:YES];
    
    // This sets it up
    [self setupInitialTextViewSharedState];
    
    // This makes sure the window's UI (including text view shared state) is updated to reflect the document
    [self setupWindowForDocument];
    
    // Changes to the zoom popup need to be communicated to the document
    if ([[self document] hasMultiplePages]) [scrollView setScaleFactor:[[self document] scaleFactor] adjustPopup:YES];
    [scrollView addObserver:self forKeyPath:@"scaleFactor" options:0 context:NULL];
    
    [[[self document] undoManager] removeAllActions];
}

- (void)setDocumentEdited:(BOOL)edited {
    [super setDocumentEdited:edited];
}

/* This method causes the text to be laid out in the foreground (approximately) up to the indicated character index.
*/
- (void)doForegroundLayoutToCharacterIndex:(NSUInteger)loc {
    NSUInteger len;
    if (loc > 0 && (len = [[[self document] textStorage] length]) > 0) {
        NSRange glyphRange;
        if (loc >= len) loc = len - 1;
        /* Find out which glyph index the desired character index corresponds to */
        glyphRange = [[self layoutManager] glyphRangeForCharacterRange:NSMakeRange(loc, 1) actualCharacterRange:NULL];
        if (glyphRange.location > 0) {
            /* Now cause layout by asking a question which has to determine where the glyph is */
            (void)[[self layoutManager] textContainerForGlyphAtIndex:glyphRange.location - 1 effectiveRange:NULL];
        }
    }
}

/* doToggleRich, called from toggleRich: or the endToggleRichSheet:... alert panel method, toggles the isRichText state (with undo)
*/
- (void)doToggleRichWithNewURL:(NSURL *)newURL {
    Document *doc = [self document];
    BOOL rich = [doc isRichText], newRich = !rich;
    NSUndoManager *undoMgr = [doc undoManager];
    
    [undoMgr registerUndoWithTarget:doc selector:@selector(setFileType:) object:[doc fileType]];
    [undoMgr registerUndoWithTarget:self selector:@selector(doToggleRichWithNewURL:) object:[doc fileURL]];

    [doc setRichText:newRich];
    [doc setFileURL:newURL];
    [self convertTextForRichTextStateRemoveAttachments:rich];
    
    if (![undoMgr isUndoing]) {
	[undoMgr setActionName:newRich ? NSLocalizedString(@"Make Rich Text", @"Undo menu item text (without 'Undo ') for making a document rich text") : NSLocalizedString(@"Make Plain Text", @"Undo menu item text (without 'Undo ') for making a document plain text")];
    }
}

/* toggleRich: puts up an alert before ultimately calling -doToggleRichWithNewURL:
*/
- (void)toggleRich:(id)sender {
    // Check if there is any loss of information
    if ([[self document] toggleRichWillLoseInformation]) {
        NSBeginAlertSheet(NSLocalizedString(@"Convert this document to plain text?", @"Title of alert confirming Make Plain Text"),
			  NSLocalizedString(@"OK", @"OK"), NSLocalizedString(@"Cancel", @"Button choice allowing user to cancel."), nil, [[self document] windowForSheet], 
			  self, NULL, @selector(didEndToggleRichSheet:returnCode:contextInfo:), NULL,
			  NSLocalizedString(@"Making a rich text document plain will lose all text styles (such as fonts and colors), images, attachments, and document properties.", @"Subtitle of alert confirming Make Plain Text"));
    } else {
        [self doToggleRichWithNewURL:nil];
    }
}

- (void)didEndToggleRichSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) [self doToggleRichWithNewURL:nil];
}

@end


@implementation DocumentWindowController(Delegation)

/* Window delegation messages */

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)defaultFrame {
    if (!hasMultiplePages) {	// If not wrap-to-page, use the default suggested
        return defaultFrame;
    } else {
        NSRect currentFrame = [window frame];	// Get the current size and location of the window
        NSRect standardFrame;
        NSSize paperSize = [[[self document] printInfo] paperSize];	// Get a frame size that fits the current printable page
        NSRect newScrollView;
	
        // Get a frame for the window content, which is a scrollView
        newScrollView.origin = NSZeroPoint;
        newScrollView.size = [[scrollView class] frameSizeForContentSize:paperSize hasHorizontalScroller:[scrollView hasHorizontalScroller] hasVerticalScroller:[scrollView hasVerticalScroller] borderType:[scrollView borderType]];
	
        // The standard frame for the window is now the frame that will fit the scrollView content
        standardFrame.size = [[window class] frameRectForContentRect:newScrollView styleMask:[window styleMask]].size;
        
        // Set the top left of the standard frame to be the same as that of the current window
        standardFrame.origin.y = NSMaxY(currentFrame) - standardFrame.size.height;
        standardFrame.origin.x = currentFrame.origin.x;
	
        return standardFrame;
    }
}

- (void)windowDidResize:(NSNotification *)notification {
    [[self document] setTransient:NO]; // Since the user has taken an interest in the window, clear the document's transient status

    if (!isSettingSize) {   // There is potential for recursion, but typically this is prevented in NSWindow which doesn't call this method if the frame doesn't change. However, just in case...
	isSettingSize = YES;
	NSSize viewSize = [[scrollView class] contentSizeForFrameSize:[scrollView frame].size hasHorizontalScroller:[scrollView hasHorizontalScroller] hasVerticalScroller:[scrollView hasVerticalScroller] borderType:[scrollView borderType]];
	
	if (![[self document] hasMultiplePages]) {
	    viewSize.width -= (defaultTextPadding() * 2.0);
	}
	[[self document] setViewSize:viewSize];
	isSettingSize = NO;
    }
}

- (void)windowDidMove:(NSNotification *)notification {
    [[self document] setTransient:NO]; // Since the user has taken an interest in the window, clear the document's transient status
}

/* Text view delegation messages */

- (BOOL)textView:(NSTextView *)textView clickedOnLink:(id)link atIndex:(NSUInteger)charIndex {
    NSURL *linkURL = nil;
    
    if ([link isKindOfClass:[NSURL class]]) {	// Handle NSURL links
        linkURL = link;
    } else if ([link isKindOfClass:[NSString class]]) {	// Handle NSString links
        linkURL = [NSURL URLWithString:link relativeToURL:[[self document] fileURL]];
    }
    if (linkURL) {
	// Special case: We want to open text types in TextEdit, as presumably that is what was desired
        if ([linkURL isFileURL]) {
            NSString *path = [linkURL path];
            if (path) {
                NSString *extension = [path pathExtension];
                if (extension && [[NSAttributedString textFileTypes] containsObject:extension]) {
                    if ([[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:linkURL display:YES error:nil] != nil) return YES;                    
                }
                if ([[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil]) return YES;
            }
        } else {
            if ([[NSWorkspace sharedWorkspace] openURL:linkURL]) return YES;
        }
    }
    
    // We only get here on failure... Because we beep, we return YES to indicate "success", so the text system does no further processing.
    NSBeep();
    return YES;
}

- (void)textView:(NSTextView *)view doubleClickedOnCell:(id <NSTextAttachmentCell>)cell inRect:(NSRect)rect atIndex:(NSUInteger)inIndex {
	if ([[cell attachment] isKindOfClass:[FoldedTextAttachment class]])
	{
		[(TextView *)view unfoldAttachment:(FoldedTextAttachment *)[cell attachment] atIndex:inIndex];
	}
	else
	{
		BOOL success = NO;
		NSString *name = [[[cell attachment] fileWrapper] filename];
		NSURL *docURL = [[self document] fileURL];
		if (docURL && name && [docURL isFileURL]) {
		NSString *docPath = [docURL path];
			NSString *pathToAttachment = [docPath stringByAppendingPathComponent:name];
			if (pathToAttachment) success = [[NSWorkspace sharedWorkspace] openFile:pathToAttachment];
		}
		if (!success) {
			if ([[self document] isDocumentEdited]) {
			NSBeginAlertSheet(NSLocalizedString(@"The attached document could not be opened.", @"Title of alert indicating attached document in TextEdit file could not be opened."),
					  NSLocalizedString(@"OK", @"OK"), nil, nil, [view window], self, NULL, NULL, nil, 
					  NSLocalizedString(@"This is likely because the file has not yet been saved.  If possible, try again after saving.", @"Message indicating text attachment could not be opened, likely because document has not yet been saved."));
		}
			NSBeep();
		}
	}
}

- (NSArray *)textView:(NSTextView *)view writablePasteboardTypesForCell:(id <NSTextAttachmentCell>)cell atIndex:(NSUInteger)charIndex {
    NSString *name = [[[cell attachment] fileWrapper] filename];
    NSURL *docURL = [[self document] fileURL];
    return (docURL && [docURL isFileURL] && name) ? [NSArray arrayWithObject:NSFilenamesPboardType] : nil;
}

- (BOOL)textView:(NSTextView *)view writeCell:(id <NSTextAttachmentCell>)cell atIndex:(NSUInteger)charIndex toPasteboard:(NSPasteboard *)pboard type:(NSString *)type {
    NSString *name = [[[cell attachment] fileWrapper] filename];
    NSURL *docURL = [[self document] fileURL];
    if ([type isEqualToString:NSFilenamesPboardType] && name && [docURL isFileURL]) {
	NSString *docPath = [docURL path];
	NSString *pathToAttachment = [docPath stringByAppendingPathComponent:name];
        if (pathToAttachment) {
	    [pboard setPropertyList:[NSArray arrayWithObject:pathToAttachment] forType:NSFilenamesPboardType];
	    return YES;
	}
    }
    return NO;
}

/* Layout manager delegation message */

- (void)layoutManager:(NSLayoutManager *)layoutManager didCompleteLayoutForTextContainer:(NSTextContainer *)textContainer atEnd:(BOOL)layoutFinishedFlag {
    if (hasMultiplePages) {
        NSArray *containers = [layoutManager textContainers];
	
        if (!layoutFinishedFlag || (textContainer == nil)) {
            // Either layout is not finished or it is but there are glyphs laid nowhere.
            NSTextContainer *lastContainer = [containers lastObject];
	    
            if ((textContainer == lastContainer) || (textContainer == nil)) {
                // Add a new page if the newly full container is the last container or the nowhere container.
                // Do this only if there are glyphs laid in the last container (temporary solution for 3729692, until AppKit makes something better available.)
                if ([layoutManager glyphRangeForTextContainer:lastContainer].length > 0) [self addPage];
            }
        } else {
            // Layout is done and it all fit.  See if we can axe some pages.
            NSUInteger lastUsedContainerIndex = [containers indexOfObjectIdenticalTo:textContainer];
            NSUInteger numContainers = [containers count];
            while (++lastUsedContainerIndex < numContainers) {
                [self removePage];
            }
        }
    }
}

@end


@implementation DocumentWindowController(NSMenuValidation)

- (BOOL)validateMenuItem:(NSMenuItem *)aCell {
    if ([aCell action] == @selector(toggleRich:)) {
	validateToggleItem(aCell, [[self document] isRichText], NSLocalizedString(@"&Make Plain Text", @"Menu item to make the current document plain text"), NSLocalizedString(@"&Make Rich Text", @"Menu item to make the current document rich text"));
        if ([[self document] isReadOnly]) return NO;
    }
    
    return YES;
}

@end
