//  SEEFindAndReplaceViewController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 24.02.14.

#import "SEEFindAndReplaceViewController.h"
#import "FindReplaceController.h"
#import "PlainTextWindowController.h"
#import "PlainTextEditor.h"
#import "PlainTextWindowControllerTabContext.h"
#import "SEETextView.h"
#import "TCMDragImageView.h"

enum OptionsMenuTags {
	kOptionMenuIgnoreCaseTag = 10001,
	kOptionMenuWrapAroundTag,
	kOptionMenuClearScopeTag,
	kOptionMenuAddSelectionToSearchScopeTag,
	kOptionMenuUseRegularExpressionsTag,

	kOptionMenuSelectedLanguageDialectTag,
	kOptionMenuSwitchLanguageDialectTag,

	kOptionMenuCaptureGroupsTag,
	kOptionMenuLineContextTag,
	kOptionMenuMultilineTag,
	kOptionMenuExtendedTag,
	kOptionMenuIgnoreEmptyMatchesTag,
	kOptionMenuOnlyLongestMatchTag,
	
	kOptionMenuEscapeCharacterSlashTag,
	kOptionMenuEscapeCharacterYenTag,
	};

static NSString * const kOptionKeyPathCaseSensitive = @"content.caseSensitive";
static NSString * const kOptionKeyPathWrapsAround   = @"content.shouldWrap";
static NSString * const kOptionKeyPathUseRegularExpressions   = @"content.useRegex";
static NSString * const kOptionKeyPathRegexDialectString = @"content.regularExpressionSyntaxString";
static NSString * const kOptionKeyPathRegexDialect = @"content.regularExpressionSyntax";
static NSString * const kOptionKeyPathRegexEscapeCharacter = @"content.regularExpressionEscapeCharacter";
static NSString * const kOptionKeyPathRegexOptionCaptureGroups = @"content.regularExpressionOptionCaptureGroups";
static NSString * const kOptionKeyPathRegexOptionLineContext = @"content.regularExpressionOptionLineContext";
static NSString * const kOptionKeyPathRegexOptionMultiline = @"content.regularExpressionOptionMultiline";
static NSString * const kOptionKeyPathRegexOptionExtended = @"content.regularExpressionOptionExtended";
static NSString * const kOptionKeyPathRegexOptionIgnoreEmptyMatches = @"content.regularExpressionOptionIgnoreEmptyMatches";
static NSString * const kOptionKeyPathRegexOptionOnlyLongestMatch = @"content.regularExpressionOptionOnlyLongestMatch";

static NSInteger const kMinViewHeight = 61;

@interface SEEFindAndReplaceViewController () <NSMenuDelegate, TCMDragImageDelegate>
@property (nonatomic, strong) IBOutlet NSPopUpButton *searchOptionsPopUpButton;
@property (nonatomic, strong) NSMenu *optionsPopupMenu;
@property (nonatomic, strong) NSMenu *recentsMenu;
@property (nonatomic, strong) NSMutableSet *registeredNotifications;
@property (nonatomic, readonly) SEETextView *targetTextView;
@property (nonatomic, readonly) PlainTextEditor *targetPlainTextEditor;

@property (nonatomic) NSInteger startHeightBeforeDrag;

@property (nonatomic, strong) NSResponder *firstResponderWhenDisabelingView;
@end

@implementation SEEFindAndReplaceViewController

- (instancetype)init {
	self = [super initWithNibName:@"SEEFindAndReplaceView" bundle:nil];
	if (self) {
		self.registeredNotifications = [NSMutableSet new];
	}
	return self;
}

- (void)dealloc {
	[self.findAndReplaceStateObjectController removeObserver:self forKeyPath:kOptionKeyPathUseRegularExpressions];
	for (id notificationReference in self.registeredNotifications) {
		[[NSNotificationCenter defaultCenter] removeObserver:notificationReference];
	}
}

- (void)setEnabled:(BOOL)isEnabled {
	NSWindow *window = self.view.window;
	id firstResponder = window.firstResponder;

	if (! isEnabled) {
		NSText *fieldEditor = [window fieldEditor:NO forObject:nil];
		if (firstResponder == fieldEditor) {
			firstResponder = fieldEditor.delegate;
			[window endEditingFor:firstResponder]; // commit changes
		}

		self.firstResponderWhenDisabelingView = firstResponder;
	}

	for (id element in @[self.findTextField,
                         self.replaceTextField,
                         self.findPreviousNextSegmentedControl,
                         self.replaceButton,
                         self.replaceAllButton,
                         self.searchOptionsPopUpButton,
                         self.findAllButton,
                       ]) {
		[element setEnabled:isEnabled];
	}

	if (isEnabled) {
		if ([firstResponder isKindOfClass:[NSWindow class]]) { // window lost it's first responder by disabling UI and set itself as first responder
			NSResponder *previousResponder = self.firstResponderWhenDisabelingView;
			if ([previousResponder respondsToSelector:@selector(window)] &&
				[[(id)previousResponder window] isEqual:window]) { // ensure the responder hasn't been removed from the window view hiearchy
				[window makeFirstResponder:previousResponder];
			}
		}
		self.firstResponderWhenDisabelingView = nil;
	}
}


- (SEETextView *)targetTextView {
	SEETextView *result = (SEETextView *)self.targetPlainTextEditor.textView;
	return result;
}

- (PlainTextEditor *)targetPlainTextEditor {
	PlainTextEditor *result = self.plainTextWindowControllerTabContext.activePlainTextEditor;
	return result;
}

- (void)updateSearchOptionsButton {
    NSImage *image;
    [self.searchOptionsPopUpButton setImagePosition:NSNoImage];
    if ([[self.findAndReplaceStateObjectController valueForKeyPath:kOptionKeyPathUseRegularExpressions] boolValue]) {
        if (@available(macOS 11.0, *)) {
            image = [NSImage imageWithSystemSymbolName:@"staroflife.fill" accessibilityDescription:nil];
        } else {
            image = [NSImage imageNamed:@"staroflife.fill"];
        }
    } else {
        if (@available(macOS 11.0, *)) {
            image = [NSImage imageWithSystemSymbolName:@"magnifyingglass" accessibilityDescription:nil];
        } else {
            image = [NSImage imageNamed:@"magnifyingglass"];
        }
    }
    NSMenuItem *titleItem = self.searchOptionsPopUpButton.itemArray[0];
    [titleItem setImage:image];
    [self.searchOptionsPopUpButton setImagePosition:NSImageOnly];
    
    NSColor *color = self.hasSearchScope ? [NSColor searchScopeBaseColor] : [NSColor controlTextColor];
    if (@available(macOS 10.14, *)) {
        [self.searchOptionsPopUpButton setContentTintColor:color];
    }
}

- (BOOL)hasSearchScope {
	BOOL result = NO;
	PlainTextEditor *targetEditor = self.targetPlainTextEditor;
	result = [targetEditor hasSearchScope];
	return result;
}

- (void)loadView {
	[super loadView];
    
	[self.findTextField bind:@"value" toObject:self.findAndReplaceStateObjectController withKeyPath:@"content.findString" options:
     @{NSContinuouslyUpdatesValueBindingOption : @YES, NSNullPlaceholderBindingOption : self.findTextField.placeholderString}];
	[self.replaceTextField bind:@"value" toObject:self.findAndReplaceStateObjectController withKeyPath:@"content.replaceString" options:
     @{NSContinuouslyUpdatesValueBindingOption : @YES, NSNullPlaceholderBindingOption : self.replaceTextField.placeholderString}];
    [self.feedbackTextField bind:@"value" toObject:self.findAndReplaceStateObjectController withKeyPath:@"content.statusString" options:
     @{NSNullPlaceholderBindingOption : @YES}];
    
	// add observation
	[self.findAndReplaceStateObjectController addObserver:self forKeyPath:kOptionKeyPathUseRegularExpressions options:0 context:(void *)kOptionMenuUseRegularExpressionsTag];
	
	__weak typeof(self) weakSelf = self;
	[self.registeredNotifications addObject:[[NSNotificationCenter defaultCenter] addObserverForName:PlainTextEditorDidChangeSearchScopeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		[weakSelf updateSearchOptionsButton];
	}]];

    [self.registeredNotifications addObject:[[NSNotificationCenter defaultCenter] addObserverForName:SEEPlainTextWindowControllerTabContextActiveEditorDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ([note.object isEqual:strongSelf.plainTextWindowControllerTabContext]) {
            [strongSelf updateSearchOptionsButton];
        }
    }]];
	
    self.searchOptionsPopUpButton.menu = [self ensuredOptionsPopupMenu];
    [self updateSearchOptionsButton];
    
	NSNumber *defaultHeight = [[NSUserDefaults standardUserDefaults] objectForKey:@"SEEFindAndReplaceOverlayDefaultHeight"];
	if (defaultHeight.integerValue >= kMinViewHeight) {
		self.mainViewHeightConstraint.constant = defaultHeight.integerValue;
	}
}

- (NSObjectController *)findAndReplaceStateObjectController {
	return [FindReplaceController sharedInstance].globalFindAndReplaceStateController;
}

- (IBAction)findAndReplaceAction:(id)aSender {
	[[FindReplaceController sharedInstance] performFindPanelAction:aSender inTargetTextView:self.targetTextView];
	if (aSender == self.findTextField) {
		[self.view.window makeFirstResponder:self.targetTextView];
	}
}

- (IBAction)dismissAction:(id)sender {
	// this is a little bit bad because it knows about the first plain text editor being the one displaying us
	[self.plainTextWindowControllerTabContext.plainTextEditors.firstObject findAndReplaceViewControllerDidPressDismiss:self];
}

- (IBAction)findPreviousNextSegmentedControlAction:(id)aSender {
	NSSegmentedControl *control = (NSSegmentedControl *)aSender;
	NSInteger actionType = (control.selectedSegment == 0) ? NSTextFinderActionPreviousMatch : NSTextFinderActionNextMatch;
	[[FindReplaceController sharedInstance] performTextFinderAction:actionType textView:self.targetTextView];
}

#pragma mark - Options Menu methods

- (IBAction)clearSearchScope:(id)aSender {
	PlainTextEditor *editor = self.targetPlainTextEditor;
	[editor clearSearchScope:aSender];
}

- (IBAction)addCurrentSelectionToSearchScope:(id)aSender {
	PlainTextEditor *editor = self.targetPlainTextEditor;
	[editor addCurrentSelectionToSearchScope:aSender];
}

- (IBAction)switchRegexSyntaxDialect:(id)aSender {
	NSString *keyPath = kOptionKeyPathRegexDialect;
	[self.findAndReplaceStateObjectController setValue:@([aSender tag]) forKeyPath:keyPath];
}

- (IBAction)toggleIgnoreCase:(id)aSender {
	NSString *keyPath = kOptionKeyPathCaseSensitive;
	NSNumber *currentValue = [self.findAndReplaceStateObjectController valueForKeyPath:keyPath];
	[self.findAndReplaceStateObjectController setValue:@(!currentValue.boolValue) forKeyPath:keyPath];
}

- (IBAction)toggleWrapAround:(id)aSender {
	NSString *keyPath = kOptionKeyPathWrapsAround;
	NSNumber *currentValue = [self.findAndReplaceStateObjectController valueForKeyPath:keyPath];
	[self.findAndReplaceStateObjectController setValue:@(!currentValue.boolValue) forKeyPath:keyPath];
}

- (IBAction)toggleUseRegex:(id)aSender {
	NSString *keyPath = kOptionKeyPathUseRegularExpressions;
	NSNumber *currentValue = [self.findAndReplaceStateObjectController valueForKeyPath:keyPath];
	[self.findAndReplaceStateObjectController setValue:@(!currentValue.boolValue) forKeyPath:keyPath];
}

- (IBAction)switchEscapeCharacter:(id)aSender {
	NSString *keyPath = kOptionKeyPathRegexEscapeCharacter;
	NSString *value = ([aSender tag] == kOptionMenuEscapeCharacterYenTag ? OgreGUIYenCharacter : OgreBackslashCharacter);
	[self.findAndReplaceStateObjectController setValue:value forKeyPath:keyPath];
}

/** only so we get the validate menu item callback for non active items*/
- (IBAction)dummyAction:(id)aSender {
	
}

- (NSString *)keyPathForRegexOption:(NSInteger)aRegexOption {
	switch (aRegexOption) {
		case kOptionMenuCaptureGroupsTag:
			return kOptionKeyPathRegexOptionCaptureGroups;
		case kOptionMenuLineContextTag:
			return kOptionKeyPathRegexOptionLineContext;
		case kOptionMenuMultilineTag:
			return kOptionKeyPathRegexOptionMultiline;
		case kOptionMenuExtendedTag:
			return kOptionKeyPathRegexOptionExtended;
		case kOptionMenuIgnoreEmptyMatchesTag:
			return kOptionKeyPathRegexOptionIgnoreEmptyMatches;
		case kOptionMenuOnlyLongestMatchTag:
			return kOptionKeyPathRegexOptionOnlyLongestMatch;
			
		default:
			return nil;
	}
}

- (IBAction)toggleRegexOption:(id)aSender {
	NSInteger tag = [aSender tag];
	NSString *keyPath = [self keyPathForRegexOption:tag];
	NSNumber *currentValue = [self.findAndReplaceStateObjectController valueForKeyPath:keyPath];
	[self.findAndReplaceStateObjectController setValue:@(!currentValue.boolValue) forKeyPath:keyPath];
}

#pragma mark - Options Menu Handling

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem.title isEqualToString:NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_REGEX_DIALECT",@"")]) {
        return NO;
    }
    
	BOOL useRegex = [[self.findAndReplaceStateObjectController valueForKeyPath:kOptionKeyPathUseRegularExpressions] boolValue];
	BOOL validationResultForRegexOptions = useRegex;
	
	if (menuItem.action == @selector(clearSearchScope:)) {
		NSString *titleFormat = NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_CLEAR_SCOPE","");
		BOOL hasScope = [self hasSearchScope];
		NSString *rangeString = NSLocalizedString(@"FIND_REPLACE_PANEL_SCOPE_DOCUMENT","");
		if (hasScope) {
			PlainTextEditor *targetEditor = self.targetPlainTextEditor;
			rangeString = [targetEditor searchScopeRangeString];
		}
		rangeString = [NSString stringWithFormat:@"(%@)",rangeString];
		menuItem.title = [NSString stringWithFormat:titleFormat,rangeString];
		return hasScope;
	} else if (menuItem.action == @selector(addCurrentSelectionToSearchScope:)) {
		if ([self.targetTextView selectedRange].length == 0) {
			return NO;
		}
	} else if (menuItem.action == @selector(switchRegexSyntaxDialect:)) {
		BOOL isOn = ([[self.findAndReplaceStateObjectController valueForKeyPath:kOptionKeyPathRegexDialect] integerValue] == menuItem.tag);
		[menuItem setState:isOn ? NSOnState : NSOffState];
	} else if (menuItem.action == @selector(toggleRegexOption:)) {
		NSInteger tag = [menuItem tag];
		NSString *keyPath = [self keyPathForRegexOption:tag];
		NSNumber *currentValue = [self.findAndReplaceStateObjectController valueForKeyPath:keyPath];
		[menuItem setState:currentValue.boolValue ? NSOnState : NSOffState];
		return validationResultForRegexOptions;
    } else if (menuItem.action == @selector(clearRecents:)) {
        return YES;
    } else if (menuItem.action == @selector(toggleRememberRecents:)) {
        [menuItem setState:[[NSUserDefaults standardUserDefaults] boolForKey:kSEEFindAndReplaceDiscardHistoryKey] ? NSControlStateValueOff : NSControlStateValueOn];
        return YES;
	} else {
		switch (menuItem.tag) {
			case kOptionMenuIgnoreCaseTag:
				[menuItem setState:[[self.findAndReplaceStateObjectController valueForKeyPath:kOptionKeyPathCaseSensitive] boolValue] ? NSOffState : NSOnState];
				break;
			case kOptionMenuWrapAroundTag:
				[menuItem setState:[[self.findAndReplaceStateObjectController valueForKeyPath:kOptionKeyPathWrapsAround] boolValue] ? NSOnState : NSOffState];
				break;
			case kOptionMenuUseRegularExpressionsTag:
				[menuItem setState:useRegex ? NSOnState	: NSOffState];
				break;
			
			case kOptionMenuSelectedLanguageDialectTag:
			{
				NSMutableArray *array = [@[[self.findAndReplaceStateObjectController valueForKeyPath:kOptionKeyPathRegexDialectString],[self.findAndReplaceStateObjectController valueForKeyPath:kOptionKeyPathRegexEscapeCharacter]] mutableCopy];
				if ([[self.findAndReplaceStateObjectController valueForKeyPath:kOptionKeyPathRegexOptionExtended] boolValue]) {
					[array addObject:@"Extended"];
				}
				array[1] = [NSString stringWithFormat:@"(%@)", [[array subarrayWithRange:NSMakeRange(1, array.count - 1)] componentsJoinedByString:@", "]];
				if (array.count > 2) {
					[array removeObjectsInRange:NSMakeRange(2, array.count - 2)];
				}
				
				[menuItem setTitle:[array componentsJoinedByString:@" "]];
				return validationResultForRegexOptions;
			}
			
			case kOptionMenuEscapeCharacterSlashTag:
				[menuItem setState:[[self.findAndReplaceStateObjectController valueForKeyPath:kOptionKeyPathRegexEscapeCharacter] isEqualToString:OgreBackslashCharacter] ? NSOnState : NSOffState];
				return validationResultForRegexOptions;

			case kOptionMenuEscapeCharacterYenTag:
				[menuItem setState:[[self.findAndReplaceStateObjectController valueForKeyPath:kOptionKeyPathRegexEscapeCharacter] isEqualToString:OgreGUIYenCharacter] ? NSOnState : NSOffState];
				return validationResultForRegexOptions;

			default:
				break;
		}
	}
	return YES;
}

- (NSMenuItem *)addItemToMenu:(NSMenu *)aMenu title:(NSString *)aTitle action:(SEL)anAction tag:(NSInteger)aTag {
	NSMenuItem *result = [aMenu addItemWithTitle:SEE_NoLocalizationNeeded(aTitle) action:anAction keyEquivalent:@""];
	result.target = self;
	result.tag = aTag;
	return result;
}

- (NSMenu *)ensuredOptionsPopupMenu {
	if (!self.optionsPopupMenu) {
		self.optionsPopupMenu = ({
			NSMenu *menu = [NSMenu new];
			menu.delegate = self;
            
			NSMenuItem *item = [menu addItemWithTitle:NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_HISTORY_SUBMENU_TITLE", @"") action:NULL keyEquivalent:@""];
			item.submenu = [NSMenu new];
			item.submenu.delegate = self;
			self.recentsMenu = item.submenu;
            
            NSMenuItem *menuTitleItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
            [menu insertItem:menuTitleItem atIndex:0];
            
			[menu addItem:[NSMenuItem separatorItem]];
			[self addItemToMenu:menu title:NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_CLEAR_SCOPE",@"") action:@selector(clearSearchScope:) tag:kOptionMenuClearScopeTag];
			[self addItemToMenu:menu title:NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_ADD_TO_SCOPE",@"") action:@selector(addCurrentSelectionToSearchScope:) tag:kOptionMenuAddSelectionToSearchScopeTag];
			[menu addItem:[NSMenuItem separatorItem]];
			[self addItemToMenu:menu title:NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_IGNORE_CASE",@"") action:@selector(toggleIgnoreCase:) tag:kOptionMenuIgnoreCaseTag];
			[self addItemToMenu:menu title:NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_WRAP",@"") action:@selector(toggleWrapAround:) tag:kOptionMenuWrapAroundTag];

			[menu addItem:[NSMenuItem separatorItem]];
			[self addItemToMenu:menu title:NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_USE_REGEX",@"") action:@selector(toggleUseRegex:) tag:kOptionMenuUseRegularExpressionsTag];

			[menu addItem:[NSMenuItem separatorItem]];
            NSMenuItem *menuDialectTitleItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_REGEX_DIALECT",@"") action:@selector(dummyAction:) keyEquivalent:@""];
            [menuDialectTitleItem setEnabled:NO];
            [menu addItem:menuDialectTitleItem];
			NSMenuItem *switchDialectMenuItem = [self addItemToMenu:menu title:@"<current selected dialect>" action:@selector(dummyAction:) tag:kOptionMenuSelectedLanguageDialectTag];
            [switchDialectMenuItem setIndentationLevel:1];
			[switchDialectMenuItem setSubmenu:({
				NSMenu *submenu = [NSMenu new];
                for (NSNumber *syntaxOptionNumber in @[
                         @(OgreRubySyntax),
                         @(OgrePerlSyntax),
                         @(OgreJavaSyntax),
                         @(OgreGNURegexSyntax),
                         @(OgreGrepSyntax),
                         @(OgreEmacsSyntax),
                         @(OgrePOSIXExtendedSyntax),
                         @(OgrePOSIXBasicSyntax),
                     ]) {
					OgreSyntax syntax = syntaxOptionNumber.integerValue;
					[self addItemToMenu:submenu title:[SEEFindAndReplaceState regularExpressionSyntaxStringForSyntax:syntax] action:@selector(switchRegexSyntaxDialect:) tag:syntax];
				}
				[submenu addItem:[NSMenuItem separatorItem]];
				[self addItemToMenu:submenu title:NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_EXTENDED",@"") action:@selector(toggleRegexOption:) tag:kOptionMenuExtendedTag];
				[submenu addItem:[NSMenuItem separatorItem]];
				[self addItemToMenu:submenu title:NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_ESCAPE_SLASH",@"") action:@selector(switchEscapeCharacter:) tag:kOptionMenuEscapeCharacterSlashTag];
				[self addItemToMenu:submenu title:NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_ESCAPE_YEN",@"") action:@selector(switchEscapeCharacter:) tag:kOptionMenuEscapeCharacterYenTag];
				
				submenu;
			})];
			
			// todo: addSubmenu

			[menu addItem:[NSMenuItem separatorItem]];
			[self addItemToMenu:menu title:NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_CAPTURE_GROUPS",@"") action:@selector(toggleRegexOption:) tag:kOptionMenuCaptureGroupsTag];
			[self addItemToMenu:menu title:NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_LINE_CONTEXT",@"") action:@selector(toggleRegexOption:) tag:kOptionMenuLineContextTag];
			[self addItemToMenu:menu title:NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_MULTILINE",@"") action:@selector(toggleRegexOption:) tag:kOptionMenuMultilineTag];
			

			[menu addItem:[NSMenuItem separatorItem]];
			[self addItemToMenu:menu title:NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_ONLY_LONGEST",@"") action:@selector(toggleRegexOption:) tag:kOptionMenuOnlyLongestMatchTag];
			[self addItemToMenu:menu title:NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_IGNORE_EMPTY",@"") action:@selector(toggleRegexOption:) tag:kOptionMenuIgnoreEmptyMatchesTag];


			[menu addItem:[NSMenuItem separatorItem]];
			[[self addItemToMenu:menu title:NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_OPEN_HELP",@"") action:@selector(showRegExHelp:) tag:0] setTarget:nil];
			menu;
		});
	}
	return self.optionsPopupMenu;
}

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel {
	return YES;
}

#pragma mark NSTextFieldDelegate

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
	if (commandSelector == @selector(cancelOperation:)) {
		[self dismissAction:control];
		return YES;
	} else if (commandSelector == @selector(insertTab:) &&
			   control == self.replaceTextField) {
		[self.targetTextView.window makeFirstResponder:self.targetTextView];
		return YES;
	} else {
		return NO;
	}
}

#pragma mark - NSMenu delegate

- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu {
	NSInteger result = menu.itemArray.count;
	if ([menu isEqual:self.recentsMenu]) {
		result = [[FindReplaceController sharedInstance] findReplaceHistory].count + 3;
	}
	return result;
}

- (void)menuWillOpen:(NSMenu *)menu {
	if ([menu isEqual:self.recentsMenu]) {
		[menu removeAllItems];
		[[[FindReplaceController sharedInstance] findReplaceHistory] enumerateObjectsUsingBlock:^(SEEFindAndReplaceState *state, NSUInteger idx, BOOL *stop) {
			NSMenuItem *item = [self addItemToMenu:menu title:state.menuTitleDescription action:@selector(takeFindAndReplaceStateFromMenuItem:) tag:0];
			item.representedObject = state;
		}];
        [menu addItem:[NSMenuItem separatorItem]];
        [self addItemToMenu:menu title:NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_REMEMBER_RECENTS",@"") action:@selector(toggleRememberRecents:) tag:1];
        [self addItemToMenu:menu title:NSLocalizedString(@"FIND_REPLACE_PANEL_MENU_CLEAR_RECENTS",@"") action:@selector(clearRecents:) tag:2];
	}
	//	NSLog(@"%s menu: %@",__FUNCTION__,menu);
}

- (void)takeFindAndReplaceStateFromMenuItem:(NSMenuItem *)anItem {
	SEEFindAndReplaceState *state = anItem.representedObject;
	[[FindReplaceController sharedInstance] takeGlobalFindAndReplaceStateValuesFromState:state];
}

- (IBAction)toggleRememberRecents:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:![defaults boolForKey:kSEEFindAndReplaceDiscardHistoryKey] forKey:kSEEFindAndReplaceDiscardHistoryKey];
}

- (IBAction)clearRecents:(id)sender {
    [[FindReplaceController sharedInstance] clearFindReplaceHistory];
}

#pragma mark - resize dragging

- (void)setOverlayViewHeight:(CGFloat)aDesiredHeight {
	aDesiredHeight = MIN(aDesiredHeight, 176);
	aDesiredHeight = MAX(aDesiredHeight, kMinViewHeight);
	
	if (self.mainViewHeightConstraint.constant != aDesiredHeight) {
		self.mainViewHeightConstraint.constant = aDesiredHeight;
		[[NSUserDefaults standardUserDefaults] setObject:@(aDesiredHeight) forKey:@"SEEFindAndReplaceOverlayDefaultHeight"];
	}
}

- (void)dragImage:(TCMDragImageView *)aDragImageView mouseDown:(NSEvent *)anEvent {
	self.startHeightBeforeDrag = self.mainViewHeightConstraint.constant;
}

- (void)dragImage:(TCMDragImageView *)aDragImageView mouseDragged:(NSEvent *)anEvent {
	CGFloat newHeight = self.startHeightBeforeDrag - aDragImageView.dragDelta.y;
	[self setOverlayViewHeight:newHeight];
}

- (void)dragImage:(TCMDragImageView *)aDragImageView mouseUp:(NSEvent *)anEvent {
	[self dragImage:aDragImageView mouseDragged:anEvent]; // take the last bit of movement too
	PlainTextEditor *topEditor = self.plainTextWindowControllerTabContext.plainTextEditors.firstObject;
	[topEditor updateTopScrollViewInset];
	[topEditor adjustToScrollViewInsets];
}

#pragma mark - key value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == (void *)kOptionMenuUseRegularExpressionsTag) {
		[self updateSearchOptionsButton];
	}
}

@end
