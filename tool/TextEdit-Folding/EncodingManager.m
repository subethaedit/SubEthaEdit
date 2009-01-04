/*
        EncodingManager.m
        Copyright (c) 2002-2007 by Apple Computer, Inc., all rights reserved.
        Author: Ali Ozer
        
        Helper class providing additional functionality for character encodings.
        This file also defines EncodingPopUpButtonCell and EncodingPopUpButton classes.
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

#import <Cocoa/Cocoa.h>
#import "EncodingManager.h"


/* EncodingPopUpButton is a subclass of NSPopUpButton which provides the ability to automatically recompute its contents on changes to the encodings list. This allows sprinkling these around the app any have them automatically update themselves.  EncodingPopUpButtonCell is the corresponding cell. It would normally not be needed, but we really want to know when the cell's selectedItem is changed, as we want to prevent the last item ("Customize...") from being selected.
*/
@interface EncodingPopUpButtonCell : NSPopUpButtonCell
@end

@implementation EncodingPopUpButtonCell

/* Do not allow selecting the "Customize" item and the separator before it. (Note that the customize item can be chosen and an action will be sent, but the selection doesn't change to it.)
*/
- (void)selectItemAtIndex:(NSInteger)index {
    if (index + 2 <= [self numberOfItems]) [super selectItemAtIndex:index];
}

@end


@implementation EncodingPopUpButton

/* Replace the cell, sign up for notifications.
*/
- (void)awakeFromNib {
    EncodingPopUpButtonCell *newCell = [[EncodingPopUpButtonCell alloc] init];
    [newCell setAction:[[self cell] action]];
    [newCell setTarget:[[self cell] target]];
    [newCell setControlSize:[[self cell] controlSize]];
    [newCell setFont:[[self cell] font]];
    [self setCell:newCell];
    [newCell release];

    [self setAutoenablesItems:NO];
    
    defaultEncoding = NoStringEncoding;
    
    if (accessibilityTitleUIElement) {
	/* Connect encoding popups to their titles for accessibility.  Standard popup cells can be connected in IB, but here we are replacing the standard cell with a new cell, so we need to connect this in code.  Note the use of NSAccessibilityUnignoredDescendant() - for accessibility purposes, the control itself is typically ignored, with the contained cell providing the accessibility information.  Use this function to operate on the correct unignored object.
	*/
	[NSAccessibilityUnignoredDescendant(self) accessibilitySetOverrideValue:NSAccessibilityUnignoredDescendant(accessibilityTitleUIElement) forAttribute: NSAccessibilityTitleUIElementAttribute];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(encodingsListChanged:) name:@"EncodingsListChanged" object:nil];
}

- (void)setEncoding:(NSStringEncoding)encoding defaultEntry:(BOOL)flag {
    defaultEncoding = encoding;
    hasDefaultEntry = flag;
    [[EncodingManager sharedInstance] setupPopUp:self selectedEncoding:defaultEncoding withDefaultEntry:hasDefaultEntry];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

/* Update contents based on encodings list customization
*/
- (void)encodingsListChanged:(NSNotification *)notification {
    NSInteger tag = [[self selectedItem] tag];
    if (tag != 0 && tag != NoStringEncoding) defaultEncoding = tag;
    [[EncodingManager sharedInstance] setupPopUp:self selectedEncoding:defaultEncoding withDefaultEntry:hasDefaultEntry];
}

@end




@implementation EncodingManager

/* Manage single shared instance which both init and sharedInstance methods return.
*/
static EncodingManager *sharedInstance = nil;

+ (EncodingManager *)sharedInstance {
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (id)init {
    if (sharedInstance) {		// We just have one instance of the EncodingManager class, return that one instead
        [self release];
    } else if (self = [super init]) {
        sharedInstance = self;
    }
    return sharedInstance;
}

- (void)dealloc {
    if (self != sharedInstance) [super dealloc];	// Don't free the shared instance
}



/* Sort using the equivalent Mac encoding as the major key. Secondary key is the actual encoding value, which works well enough. We treat Unicode encodings as special case, putting them at top of the list.
*/
static int encodingCompare(const void *firstPtr, const void *secondPtr) {
    CFStringEncoding first = *(CFStringEncoding *)firstPtr;
    CFStringEncoding second = *(CFStringEncoding *)secondPtr;
    CFStringEncoding macEncodingForFirst = CFStringGetMostCompatibleMacStringEncoding(first);
    CFStringEncoding macEncodingForSecond = CFStringGetMostCompatibleMacStringEncoding(second);
    if (first == second) return 0;	// Should really never happen
    if (macEncodingForFirst == kCFStringEncodingUnicode || macEncodingForSecond == kCFStringEncodingUnicode) {
        if (macEncodingForSecond == macEncodingForFirst) return (first > second) ? 1 : -1;	// Both Unicode; compare second order
        return (macEncodingForFirst == kCFStringEncodingUnicode) ? -1 : 1;	// First is Unicode
    }
    if ((macEncodingForFirst > macEncodingForSecond) || ((macEncodingForFirst == macEncodingForSecond) && (first > second))) return 1;
    return -1;
}

/* Return a sorted list of all available string encodings.
*/
+ (NSArray *)allAvailableStringEncodings {
    static NSMutableArray *allEncodings = nil;
    if (!allEncodings) {	// Build list of encodings, sorted, and including only those with human readable names
        const CFStringEncoding *cfEncodings = CFStringGetListOfAvailableEncodings();
        CFStringEncoding *tmp;
        NSInteger cnt, num = 0;
        while (cfEncodings[num] != kCFStringEncodingInvalidId) num++;	// Count
        tmp = malloc(sizeof(CFStringEncoding) * num);
        memcpy(tmp, cfEncodings, sizeof(CFStringEncoding) * num);	// Copy the list
        qsort(tmp, num, sizeof(CFStringEncoding), encodingCompare);	// Sort it
        allEncodings = [[NSMutableArray alloc] init];			// Now put it in an NSArray
        for (cnt = 0; cnt < num; cnt++) {
            NSStringEncoding nsEncoding = CFStringConvertEncodingToNSStringEncoding(tmp[cnt]);
            if (nsEncoding && [NSString localizedNameOfStringEncoding:nsEncoding]) [allEncodings addObject:[NSNumber numberWithUnsignedInteger:nsEncoding]];
        }
        free(tmp);
    }
    return allEncodings;
}


/* Called once (when the UI is first brought up) to properly setup the encodings list in the "Customize Encodings List" panel.
*/
- (void)setupEncodingsList {
    NSArray *allEncodings = [[self class] allAvailableStringEncodings];
    NSInteger cnt, numEncodings = [allEncodings count];

    for (cnt = 0; cnt < numEncodings; cnt++) {
        NSStringEncoding encoding = [[allEncodings objectAtIndex:cnt] unsignedIntegerValue];
        NSString *encodingName = [NSString localizedNameOfStringEncoding:encoding];
        NSCell *cell;
        if (cnt >= [encodingMatrix numberOfRows]) [encodingMatrix addRow];
        cell = [encodingMatrix cellAtRow:cnt column:0];
        [cell setTitle:encodingName];
        [cell setTag:encoding];
    }
    [encodingMatrix sizeToCells];
    [self noteEncodingListChange:NO updateList:YES postNotification:NO];
}


/* This method initializes the provided popup with list of encodings; it also sets up the selected encoding as indicated and if includeDefaultItem is YES, includes an initial item for selecting "Automatic" choice.  These non-encoding items all have NoStringEncoding as their tags. Otherwise the tags are set to the NSStringEncoding value for the encoding.
*/
- (void)setupPopUp:(EncodingPopUpButton *)popup selectedEncoding:(NSUInteger)selectedEncoding withDefaultEntry:(BOOL)includeDefaultItem {
    NSArray *encs = [self enabledEncodings];
    NSUInteger cnt, numEncodings, itemToSelect = 0;
        
    // Put the encodings in the popup
    [popup removeAllItems];

    // Put the initial "Automatic" item, if desired
    if (includeDefaultItem) {
        [popup addItemWithTitle:NSLocalizedString(@"Automatic", @"Encoding popup entry indicating automatic choice of encoding")];
        [[popup itemAtIndex:0] setTag:NoStringEncoding];
    }

    // Make sure the initial selected encoding appears in the list
    if (!includeDefaultItem && (selectedEncoding != NoStringEncoding) && ![encs containsObject:[NSNumber numberWithUnsignedInteger:selectedEncoding]]) encs = [encs arrayByAddingObject:[NSNumber numberWithUnsignedInteger:selectedEncoding]];

    numEncodings = [encs count];

    // Fill with encodings
    for (cnt = 0; cnt < numEncodings; cnt++) {
        NSStringEncoding enc = [[encs objectAtIndex:cnt] unsignedIntegerValue];
        [popup addItemWithTitle:[NSString localizedNameOfStringEncoding:enc]];
        [[popup lastItem] setTag:enc];
        [[popup lastItem] setEnabled:YES];
        if (enc == selectedEncoding) itemToSelect = [popup numberOfItems] - 1;
    }

    // Add an optional separator and "customize" item at end
    if ([popup numberOfItems] > 0) {
        [[popup menu] addItem:[NSMenuItem separatorItem]];
        [[popup lastItem] setTag:NoStringEncoding];
    }
    [popup addItemWithTitle:NSLocalizedString(@"Customize Encodings List\\U2026", @"Encoding popup entry for bringing up the Customize Encodings List panel (this also occurs as the title of the panel itself, they should have the same localization)")];
    [[popup lastItem] setAction:@selector(showPanel:)];
    [[popup lastItem] setTarget:self];
    [[popup lastItem] setTag:NoStringEncoding];

    [popup selectItemAtIndex:itemToSelect];
}


/* Returns the actual enabled list of encodings.
*/
- (NSArray *)enabledEncodings {
    static const NSInteger plainTextFileStringEncodingsSupported[] = {
        kCFStringEncodingUnicode, kCFStringEncodingUTF8, kCFStringEncodingMacRoman, kCFStringEncodingWindowsLatin1, kCFStringEncodingMacJapanese, kCFStringEncodingShiftJIS, kCFStringEncodingMacChineseTrad, kCFStringEncodingMacKorean, kCFStringEncodingMacChineseSimp, kCFStringEncodingGB_18030_2000, -1
    };
    if (encodings == nil) {
        NSMutableArray *encs = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"Encodings"] mutableCopy];
        if (encs == nil) {
            NSStringEncoding defaultEncoding = [NSString defaultCStringEncoding];
            NSStringEncoding encoding;
            BOOL hasDefault = NO;
            NSInteger cnt = 0;
            encs = [[NSMutableArray alloc] init];
            while (plainTextFileStringEncodingsSupported[cnt] != -1) {
                if ((encoding = CFStringConvertEncodingToNSStringEncoding(plainTextFileStringEncodingsSupported[cnt++])) != kCFStringEncodingInvalidId) {
                    [encs addObject:[NSNumber numberWithUnsignedInteger:encoding]];
                    if (encoding == defaultEncoding) hasDefault = YES;
                }
            }
            if (!hasDefault) [encs addObject:[NSNumber numberWithUnsignedInteger:defaultEncoding]];
        }
        encodings = encs;
    }
    return encodings;
}

/* Should be called after any customization to the encodings list. Writes the new list out to defaults; updates the UI; also posts notification to get all encoding popups to update.
*/
- (void)noteEncodingListChange:(BOOL)writeDefault updateList:(BOOL)updateList postNotification:(BOOL)post {
    if (writeDefault) [[NSUserDefaults standardUserDefaults] setObject:encodings forKey:@"Encodings"];

    if (updateList) {
        NSInteger cnt, numEncodings = [encodingMatrix numberOfRows];
        for (cnt = 0; cnt < numEncodings; cnt++) {
            NSCell *cell = [encodingMatrix cellAtRow:cnt column:0];
            [cell setState:[encodings containsObject:[NSNumber numberWithUnsignedInteger:[cell tag]]] ? NSOnState : NSOffState];
        }
    }

    if (post) [[NSNotificationCenter defaultCenter] postNotificationName:@"EncodingsListChanged" object:nil];
}

/* Because we want the encoding list to be modifiable even when a modal panel (such as the open panel) is up, we indicate that both the encodings list panel and the target work when modal. (See showPanel: below for the former...)
*/
- (BOOL)worksWhenModal {
    return YES;
}


/* Action methods */

- (IBAction)showPanel:(id)sender {
    if (!encodingMatrix) {
        if (![NSBundle loadNibNamed:@"SelectEncodingsPanel" owner:self])  {
            NSLog(@"Failed to load SelectEncodingsPanel.nib");
            return;
        }
        [(NSPanel *)[encodingMatrix window] setWorksWhenModal:YES];	// This should work when open panel is up
        [[encodingMatrix window] setLevel:NSModalPanelWindowLevel];	// Again, for the same reason
        [self setupEncodingsList];					// Initialize the list (only need to do this once)
    }
    [[encodingMatrix window] makeKeyAndOrderFront:nil];
}

- (IBAction)encodingListChanged:(id)sender {
    NSInteger cnt, numRows = [encodingMatrix numberOfRows];
    NSMutableArray *encs = [[NSMutableArray alloc] init];

    for (cnt = 0; cnt < numRows; cnt++) {
        NSCell *cell = [encodingMatrix cellAtRow:cnt column:0];
        if (([cell tag] != NoStringEncoding) && ([cell state] == NSOnState)) [encs addObject:[NSNumber numberWithUnsignedInteger:[cell tag]]];
    }

    [encodings autorelease];
    encodings = encs;

    [self noteEncodingListChange:YES updateList:NO postNotification:YES];
}

- (IBAction)clearAll:(id)sender {
    [encodings autorelease];
    encodings = [[NSArray array] retain];				// Empty encodings list
    [self noteEncodingListChange:YES updateList:YES postNotification:YES];
}

- (IBAction)selectAll:(id)sender {
    [encodings autorelease];
    encodings = [[[self class] allAvailableStringEncodings] retain];	// All encodings
    [self noteEncodingListChange:YES updateList:YES postNotification:YES];
}

- (IBAction)revertToDefault:(id)sender {
    [encodings autorelease];
    encodings = nil;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Encodings"];
    (void)[self enabledEncodings];					// Regenerate default list
    [self noteEncodingListChange:NO updateList:YES postNotification:YES];
}


@end




