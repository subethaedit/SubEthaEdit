/*
        EncodingManager.m
        Copyright (c) 2002 by Apple Computer, Inc., all rights reserved.
        Author: Ali Ozer
        
        Helper class providing additional functionality for character encodings.
        This file also defines EncodingPopUpButtonCell and EncodingPopUpButton classes.
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
    NSUInteger tag = (NSUInteger)[[self selectedItem] tag];
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

+ (instancetype)sharedInstance
{
	static dispatch_once_t onceToken = 0;
	static id sharedInstance = nil;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});
    return sharedInstance;
}

- (id)init
{
    self = [super initWithWindowNibName:@"SelectEncodingsPanel"];
    if (self) {
		registeredEncodings = [[NSCountedSet alloc] init];
    }
    return self;
}

- (void)dealloc
{
	[registeredEncodings release];
	registeredEncodings = nil;

	[super dealloc];
}

- (void)loadWindow
{
	[super loadWindow];
	if ([self.window isKindOfClass:[NSPanel class]])
	{
		NSPanel *panel = (NSPanel *)self.window;
		panel.worksWhenModal = YES; // This should work when open panel is up
		panel.level = NSModalPanelWindowLevel; // Again, for the same reason
	}
	[self setupEncodingsList]; // Initialize the list (only need to do this once)
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
		if (num > 0)
		{
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
    }
    return allEncodings;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(showWindow:)){
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
        if (cnt >= [self.encodingMatrix numberOfRows]) [self.encodingMatrix addRow];
        cell = [self.encodingMatrix cellAtRow:cnt column:0];
        [cell setTitle:encodingName];
        [cell setTag:encoding];
    }
    [self.encodingMatrix sizeToCells];
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
        
        BOOL lossy = NO;
        for (id loopItem1 in listOfEncodings) {
            if ([loopItem1 unsignedIntValue] == enc) {
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
    [[popup lastItem] setAction:@selector(showWindow:)];
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
                                                           action:@selector(showWindow:)
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
            NSStringEncoding defaultEncoding = NSUTF8StringEncoding;
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
        int cnt, numEncodings = [self.encodingMatrix numberOfRows];
        for (cnt = 0; cnt < numEncodings; cnt++) {
            NSCell *cell = [self.encodingMatrix cellAtRow:cnt column:0];
            [cell setState:[encodings containsObject:[NSNumber numberWithUnsignedInt:[cell tag]]] ? NSOnState : NSOffState];
            if ([registeredEncodings containsObject:[NSNumber numberWithUnsignedInt:[cell tag]]] ||
                [cell tag] == NSUTF8StringEncoding || [cell tag] == NSUnicodeStringEncoding) {
                [cell setEnabled:NO];
            } else {
                [cell setEnabled:YES];
            }
        }
        [self.encodingMatrix setNeedsDisplay:YES];
    }

    if (post) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"EncodingsListChanged" object:nil];
        // this is for a flicker free update of the ecodings popup in the bottom status bar
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AfterEncodingsListChanged" object:nil];
    }
}

/* Because we want the encoding list to be modifiable even when a modal panel (such as the open panel) is up, we indicate that both the encodings list panel and the target work when modal. (See showPanel: below for the former...)
*/
- (BOOL)worksWhenModal {
    return YES;
}


/* Action methods */

- (IBAction)encodingListChanged:(id)sender {
    int cnt, numRows = [self.encodingMatrix numberOfRows];
    NSMutableArray *encs = [[NSMutableArray alloc] init];

    for (cnt = 0; cnt < numRows; cnt++) {
        NSCell *cell = [self.encodingMatrix cellAtRow:cnt column:0];
        if (((NSUInteger)[cell tag] != NoStringEncoding) && ([cell state] == NSOnState)) [encs addObject:[NSNumber numberWithUnsignedInt:[cell tag]]];
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

