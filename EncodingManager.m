/*
        EncodingManager.m
        Copyright (c) 2002 by Apple Computer, Inc., all rights reserved.
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
 terms, Apple grants you a personal, non-exclusive license, under Apple’s copyrights in
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
- (void)selectItemAtIndex:(int)index {
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
    selectedEncoding = NoStringEncoding;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(encodingsListChanged:) name:@"EncodingsListChanged" object:nil];
}

- (NSStringEncoding)selectedEncoding {
    return selectedEncoding;
}

- (void)setSelectedEncoding:(NSStringEncoding)newEncoding {
    selectedEncoding = newEncoding;
}

- (void)setEncoding:(NSStringEncoding)encoding defaultEntry:(BOOL)flag modeEntry:(BOOL)modeFlag lossyEncodings:(NSArray *)encodings {
    defaultEncoding = encoding;
    selectedEncoding = encoding;
    hasDefaultEntry = flag;
    hasModeEntry = modeFlag;
    [[EncodingManager sharedInstance] setupPopUp:self selectedEncoding:defaultEncoding withDefaultEntry:hasDefaultEntry withModeEntry:hasModeEntry lossyEncodings:encodings];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

/* Update contents based on encodings list customization
*/
- (void)encodingsListChanged:(NSNotification *)notification {
    unsigned int tag = (unsigned int)[[self selectedItem] tag];
    if (tag != 0 && tag != NoStringEncoding) defaultEncoding = tag;
    [[EncodingManager sharedInstance] setupPopUp:self selectedEncoding:defaultEncoding withDefaultEntry:hasDefaultEntry withModeEntry:hasModeEntry lossyEncodings:[NSArray array]];
}

@end


@implementation EncodingMenu

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)encodingsListChanged:(NSNotification *)notification {
    //int tag = [[self selectedItem] tag];
    //if (tag != 0 && tag != NoStringEncoding) defaultEncoding = tag;
    //[[EncodingManager sharedInstance] setupPopUp:self selectedEncoding:defaultEncoding withDefaultEntry:hasDefaultEntry lossyEncodings:[NSArray array]];
    SEL theAction = [[[self itemArray] lastObject] action];
    id  target    = [[[self itemArray] lastObject] target];
    [[EncodingManager sharedInstance] setupMenu:self action:action];
    [[[self itemArray] lastObject] setAction:theAction];
    [[[self itemArray] lastObject] setTarget:target   ];
}

- (void)configureWithAction:(SEL)aSelector {
    action = aSelector;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(encodingsListChanged:) name:@"EncodingsListChanged" object:nil];
    [[EncodingManager sharedInstance] setupMenu:self action:action];
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
    } else if ((self = [super init])) {
        sharedInstance = self;
        registeredEncodings = [[NSCountedSet alloc] init];
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
        int cnt, num = 0;
        while (cfEncodings[num] != kCFStringEncodingInvalidId) num++;	// Count
        tmp = malloc(sizeof(CFStringEncoding) * num);
        memcpy(tmp, cfEncodings, sizeof(CFStringEncoding) * num);	// Copy the list
        qsort(tmp, num, sizeof(CFStringEncoding), encodingCompare);	// Sort it
        allEncodings = [[NSMutableArray alloc] init];			// Now put it in an NSArray
        for (cnt = 0; cnt < num; cnt++) {
            NSStringEncoding nsEncoding = CFStringConvertEncodingToNSStringEncoding(tmp[cnt]);
            if (nsEncoding && [NSString localizedNameOfStringEncoding:nsEncoding]) [allEncodings addObject:[NSNumber numberWithUnsignedInt:nsEncoding]];
        }
        free(tmp);
    }
    return allEncodings;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(showPanel:)){
        return YES;
    }
    
    return YES;
}

/* Called once (when the UI is first brought up) to properly setup the encodings list in the "Customize Encodings List" panel.
*/
- (void)setupEncodingsList {
    NSArray *allEncodings = [[self class] allAvailableStringEncodings];
    int cnt, numEncodings = [allEncodings count];

    for (cnt = 0; cnt < numEncodings; cnt++) {
        NSStringEncoding encoding = [[allEncodings objectAtIndex:cnt] unsignedIntValue];
        NSString *ianaName = [(NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(encoding)) lowercaseString];
        NSString *encodingName = ianaName?[NSString stringWithFormat:@"%@ [%@]",[NSString localizedNameOfStringEncoding:encoding],ianaName]:[NSString localizedNameOfStringEncoding:encoding];
        //[NSString localizedNameOfStringEncoding:encoding];
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
- (void)setupPopUp:(NSPopUpButton *)popup selectedEncoding:(unsigned)selectedEncoding withDefaultEntry:(BOOL)includeDefaultItem withModeEntry:(BOOL)includeModeItem lossyEncodings:(NSArray *)listOfEncodings {
    NSArray *encs = [self enabledEncodings];
    unsigned cnt, numEncodings, itemToSelect = 0;
        
    // Put the encodings in the popup
    [popup removeAllItems];

    // Put the "Mode" item item, if desired
    if (includeModeItem) {
        [popup addItemWithTitle:NSLocalizedString(@"Recommended by Mode", @"Encoding popup entry indicating mode choice of encoding")];
        [[popup lastItem] setTag:ModeStringEncoding];
        [[popup menu] addItem:[NSMenuItem separatorItem]];
    }
    
    // Put the initial "Automatic" item, if desired
    if (includeDefaultItem) {
        [popup addItemWithTitle:NSLocalizedString(@"Automatic", @"Encoding popup entry indicating automatic choice of encoding")];
        [[popup lastItem] setTag:NoStringEncoding];
    }

    // Make sure the initial selected encoding appears in the list
    if (!includeDefaultItem && (selectedEncoding != NoStringEncoding) && ![encs containsObject:[NSNumber numberWithUnsignedInt:selectedEncoding]]) encs = [encs arrayByAddingObject:[NSNumber numberWithUnsignedInt:selectedEncoding]];

    numEncodings = [encs count];

    // Fill with encodings
    for (cnt = 0; cnt < numEncodings; cnt++) {
        NSStringEncoding enc = [[encs objectAtIndex:cnt] unsignedIntValue];
        
        unsigned int i;
        BOOL lossy = NO;
        for (i = 0; i < [listOfEncodings count]; i++) {
            if ([[listOfEncodings objectAtIndex:i] unsignedIntValue] == enc) {
                lossy = YES;
            }
        }
        
        if (lossy) {
            unichar dashChar = 0x2014; // EM DASH
            NSString *dash = [NSString stringWithCharacters:&dashChar length:1];
            [popup addItemWithTitle:[NSString stringWithFormat:@"%@ %@ %@", [NSString localizedNameOfStringEncoding:enc], dash, NSLocalizedString(@"Lossy", nil)]];
        } else {
            [popup addItemWithTitle:[NSString localizedNameOfStringEncoding:enc]];
        }
        [[popup lastItem] setTag:enc];
        [[popup lastItem] setEnabled:YES];
        if (enc == selectedEncoding) itemToSelect = [popup numberOfItems] - 1;
    }

    // Add an optional separator and "customize" item at end
    if ([popup numberOfItems] > 0) {
        [[popup menu] addItem:[NSMenuItem separatorItem]];
        [[popup lastItem] setTag:NoStringEncoding];
    }
    [popup addItemWithTitle:NSLocalizedString(@"Customize Encodings List...", @"Encoding popup entry for bringing up the Customize Encodings List panel (this also occurs as the title of the panel itself, they should have the same localization)")];
    [[popup lastItem] setAction:@selector(showPanel:)];
    [[popup lastItem] setTarget:self];
    [[popup lastItem] setTag:NoStringEncoding];

    [popup selectItemAtIndex:itemToSelect];
}

- (void)setupMenu:(NSMenu *)aMenu action:(SEL)aSelector {

    // Remove all menu items
    int count = [aMenu numberOfItems];
    while (count) {
        [aMenu removeItemAtIndex:count - 1];
        count = [aMenu numberOfItems];
    }
    
    // Add encodings
    NSArray *myEncodings = [self enabledEncodings];
    unsigned i, numberOfEncodings;
    numberOfEncodings = [myEncodings count];
    for (i = 0; i < numberOfEncodings; i++) {
        NSStringEncoding encoding = [[myEncodings objectAtIndex:i] unsignedIntValue];
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[NSString localizedNameOfStringEncoding:encoding]
                                                          action:aSelector
                                                   keyEquivalent:@""];
        [menuItem setTag:encoding];
        [menuItem setEnabled:YES];
        [aMenu addItem:menuItem];
        [menuItem release];
    }
    
    // Add separator and customize item at end
    NSMenuItem *separator = [NSMenuItem separatorItem];
    [separator setTag:NoStringEncoding];
    [aMenu addItem:separator];
    NSMenuItem *customizeItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Customize Encodings List...", nil)
                                                           action:@selector(showPanel:)
                                                    keyEquivalent:@""];
    [customizeItem setTag:NoStringEncoding];
    [customizeItem setEnabled:YES];
    [customizeItem setTarget:self];
    [aMenu addItem:customizeItem];
    [customizeItem release];
}


/* Returns the actual enabled list of encodings.
*/
- (NSArray *)enabledEncodings {
    static const int plainTextFileStringEncodingsSupported[] = {
        kCFStringEncodingUnicode, kCFStringEncodingUTF8, kCFStringEncodingMacRoman, kCFStringEncodingWindowsLatin1, kCFStringEncodingMacJapanese, kCFStringEncodingShiftJIS, kCFStringEncodingMacChineseTrad, kCFStringEncodingMacKorean, kCFStringEncodingMacChineseSimp, kCFStringEncodingGB_18030_2000, kCFStringEncodingISOLatin1, kCFStringEncodingASCII, kCFStringEncodingNonLossyASCII, -1
    };
    if (encodings == nil) {
        NSMutableArray *encs = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"Encodings"] mutableCopy];
        if (encs == nil) {
            NSStringEncoding defaultEncoding = [NSString defaultCStringEncoding];
            NSStringEncoding encoding;
            BOOL hasDefault = NO;
            int cnt = 0;
            encs = [[NSMutableArray alloc] init];
            while (plainTextFileStringEncodingsSupported[cnt] != -1) {
                if ((encoding = CFStringConvertEncodingToNSStringEncoding(plainTextFileStringEncodingsSupported[cnt++])) != kCFStringEncodingInvalidId) {
                    [encs addObject:[NSNumber numberWithUnsignedInt:encoding]];
                    if (encoding == defaultEncoding) hasDefault = YES;
                }
            }
            if (!hasDefault) [encs addObject:[NSNumber numberWithUnsignedInt:defaultEncoding]];
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
        int cnt, numEncodings = [encodingMatrix numberOfRows];
        for (cnt = 0; cnt < numEncodings; cnt++) {
            NSCell *cell = [encodingMatrix cellAtRow:cnt column:0];
            [cell setState:[encodings containsObject:[NSNumber numberWithUnsignedInt:[cell tag]]] ? NSOnState : NSOffState];
            if ([registeredEncodings containsObject:[NSNumber numberWithUnsignedInt:[cell tag]]] ||
                [cell tag] == NSUTF8StringEncoding || [cell tag] == NSUnicodeStringEncoding) {
                [cell setEnabled:NO];
            } else {
                [cell setEnabled:YES];
            }
        }
        [encodingMatrix setNeedsDisplay:YES];
    }

    if (post) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"EncodingsListChanged" object:nil];
        // this is for a flicker free update of the ecodings popup in the bottom status bar
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AfterEncodingsListChanged" object:nil];
    }
}

/* Use this method to get a new accessory view. It reinitializes the popup, selects the specified item, and also includes or deletes the default entry (corresponding to "Automatic")
*/
- (NSView *)encodingAccessory:(unsigned)encoding includeDefaultEntry:(BOOL)includeDefaultItem enableIgnoreRichTextButton:(BOOL)includeRichTextButton encodingPopUp:(NSPopUpButton **)popup ignoreRichTextButton:(NSButton **)button lossyEncodings:(NSArray *)listOfEncodings{
    // For now rather than caching, load the accessory view everytime, as it might appear in multiple panels simultaneously.
    NSLog(@"WARNING! Method is deprecated");
    if (![NSBundle loadNibNamed:@"EncodingAccessory" owner:self])  {
        NSLog(@"Failed to load EncodingAccessory.nib");
        return nil;
    }
    if (popup) *popup = (NSPopUpButton *)encodingPopupButton;
    if (button) *button = ignoreRichTextButton;

    [ignoreRichTextButton setEnabled:includeRichTextButton];
    //[encodingPopupButton setEncoding:encoding defaultEntry:includeDefaultItem lossyEncodings:listOfEncodings];
    [encodingAccessory retain];			// Hang on to the view we want, and
    [[encodingAccessory window] release];	// ...get rid of the dummy window (should switch to custom top level view for this)
    return [encodingAccessory autorelease];
}

/* Because we want the encoding list to be modifiable even when a modal panel (such as the open panel) is up, we indicate that both the encodings list panel and the target work when modal. (See showPanel: below for the former...)
*/
- (BOOL)worksWhenModal {
    return YES;
}


/* Action methods */

- (void)ensureMatrix {
    if (!encodingMatrix) {
        if (![NSBundle loadNibNamed:@"SelectEncodingsPanel" owner:self])  {
            NSLog(@"Failed to load SelectEncodingsPanel.nib");
            return;
        }
        [(NSPanel *)[encodingMatrix window] setWorksWhenModal:YES];	// This should work when open panel is up
        [[encodingMatrix window] setLevel:NSModalPanelWindowLevel];	// Again, for the same reason
        [self setupEncodingsList];					// Initialize the list (only need to do this once)
    }
}

- (IBAction)showPanel:(id)sender {
    [self ensureMatrix];
    [[encodingMatrix window] makeKeyAndOrderFront:nil];
}


- (IBAction)encodingListChanged:(id)sender {
    int cnt, numRows = [encodingMatrix numberOfRows];
    NSMutableArray *encs = [[NSMutableArray alloc] init];

    for (cnt = 0; cnt < numRows; cnt++) {
        NSCell *cell = [encodingMatrix cellAtRow:cnt column:0];
        if (((unsigned int)[cell tag] != NoStringEncoding) && ([cell state] == NSOnState)) [encs addObject:[NSNumber numberWithUnsignedInt:[cell tag]]];
    }

    [encodings autorelease];
    encodings = encs;

    [self noteEncodingListChange:YES updateList:NO postNotification:YES];
}

- (void)activateEncoding:(NSStringEncoding)anEncoding {
    if (![encodings containsObject:[NSNumber numberWithUnsignedInt:anEncoding]]) {
        [encodings autorelease];
        encodings = [[encodings arrayByAddingObject:[NSNumber numberWithUnsignedInt:anEncoding]] retain];
        [self noteEncodingListChange:YES updateList:NO postNotification:YES];
    }
}


- (IBAction)clearAll:(id)sender {
    [encodings autorelease];
    [self registerEncoding:NSUTF8StringEncoding];
    [self registerEncoding:NSUnicodeStringEncoding];
    encodings = [[NSArray arrayWithArray:[registeredEncodings allObjects]] retain];
    [self noteEncodingListChange:YES updateList:YES postNotification:YES];
    [self unregisterEncoding:NSUnicodeStringEncoding];
    [self unregisterEncoding:NSUTF8StringEncoding];
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

- (IBAction)selectedEncoding:(id)sender {
    [self unregisterEncoding:[sender selectedEncoding]];
    [sender setSelectedEncoding:[[sender selectedItem] tag]];
    [self registerEncoding:[[sender selectedItem] tag]];
}

- (void)registerEncoding:(NSStringEncoding)encoding {
    [registeredEncodings addObject:[NSNumber numberWithUnsignedInt:encoding]];
    [self noteEncodingListChange:NO updateList:YES postNotification:NO];
}

- (void)unregisterEncoding:(NSStringEncoding)encoding {
    [registeredEncodings removeObject:[NSNumber numberWithUnsignedInt:encoding]];
    [self noteEncodingListChange:NO updateList:YES postNotification:NO];
}

@end

