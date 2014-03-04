//
//  SEEFindAndReplaceViewController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 24.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import "SEEFindAndReplaceViewController.h"
#import "FindReplaceController.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

enum OptionsMenuTags {
	kOptionMenuIgnoreCaseTag = 10001,
	kOptionMenuWrapAroundTag,
	kOptionMenuSetScopeToSelectionTag,
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


@interface SEEFindAndReplaceViewController () <NSMenuDelegate>
@property (nonatomic, strong) NSMenu *optionsPopupMenu;
@end

@implementation SEEFindAndReplaceViewController

- (instancetype)init {
	self = [super initWithNibName:@"SEEFindAndReplaceView" bundle:nil];
	if (self) {
		
	}
	return self;
}

- (void)dealloc {
	[self.findAndReplaceStateObjectController removeObserver:self forKeyPath:kOptionKeyPathUseRegularExpressions];
}

- (void)updateSearchOptionsButton {
	NSImage *image = [NSImage pdfBasedImageNamed:@"SearchLoupeNormal"TCM_PDFIMAGE_SEP@"36"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_NORMAL];
	if ([[self.findAndReplaceStateObjectController valueForKeyPath:kOptionKeyPathUseRegularExpressions] boolValue]) {
		image = [NSImage pdfBasedImageNamed:@"SearchLoupeRE"TCM_PDFIMAGE_SEP@"36"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_NORMAL];
	}
	[self.searchOptionsButton setImage:image];
}

- (void)loadView {
	[super loadView];
	NSView *view = self.view;
	view.layer.borderColor = [[NSColor lightGrayColor] CGColor];
	view.layer.borderWidth = 0.5;
	
	view.layer.backgroundColor = [[NSColor colorWithCalibratedWhite:0.893 alpha:0.750] CGColor];

	[self updateSearchOptionsButton];
	[self.searchOptionsButton sendActionOn:NSLeftMouseDownMask | NSRightMouseDownMask];
	
	// add bindings
	[self.findTextField bind:@"value" toObject:self.findAndReplaceStateObjectController withKeyPath:@"content.findString" options:@{NSContinuouslyUpdatesValueBindingOption : @YES}];
	[self.replaceTextField bind:@"value" toObject:self.findAndReplaceStateObjectController withKeyPath:@"content.replaceString" options:@{NSContinuouslyUpdatesValueBindingOption : @YES}];
	
	// add observation
	[self.findAndReplaceStateObjectController addObserver:self forKeyPath:kOptionKeyPathUseRegularExpressions options:0 context:kOptionMenuUseRegularExpressionsTag];
	
}

- (NSObjectController *)findAndReplaceStateObjectController {
	return [FindReplaceController sharedInstance].globalFindAndReplaceStateController;
}

- (IBAction)findAndReplaceAction:(id)aSender {
	[[FindReplaceController sharedInstance] performFindPanelAction:aSender inTargetTextView:self.delegate.textView];
}


- (IBAction)dismissAction:(id)sender {
	[self.delegate findAndReplaceViewControllerDidPressDismiss:self];
}

- (IBAction)searchOptionsDropdownAction:(id)sender {
	NSMenu *menu = [self ensuredOptionsPopupMenu];
	[menu popUpMenuPositioningItem:nil atLocation:({ NSPoint result = NSZeroPoint;
		result.y = NSMaxY(self.searchOptionsButton.bounds);
		result;}) inView:self.searchOptionsButton];
	
}

#pragma mark - Options Menu methods

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
	NSLog(@"%s menuItem:%@",__FUNCTION__,menuItem);
	
	BOOL useRegex = [[self.findAndReplaceStateObjectController valueForKeyPath:kOptionKeyPathUseRegularExpressions] boolValue];
	BOOL validationResultForRegexOptions = useRegex;
	
	if (menuItem.action == @selector(switchRegexSyntaxDialect:)) {
		BOOL isOn = ([[self.findAndReplaceStateObjectController valueForKeyPath:kOptionKeyPathRegexDialect] integerValue] == menuItem.tag);
		[menuItem setState:isOn ? NSOnState : NSOffState];
	} else if (menuItem.action == @selector(toggleRegexOption:)) {
		NSInteger tag = [menuItem tag];
		NSString *keyPath = [self keyPathForRegexOption:tag];
		NSNumber *currentValue = [self.findAndReplaceStateObjectController valueForKeyPath:keyPath];
		[menuItem setState:currentValue.boolValue ? NSOnState : NSOffState];
		return validationResultForRegexOptions;
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
				[menuItem setTitle:[self.findAndReplaceStateObjectController valueForKeyPath:kOptionKeyPathRegexDialectString]];
				return validationResultForRegexOptions;
			
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
	NSMenuItem *result = [aMenu addItemWithTitle:aTitle action:anAction keyEquivalent:@""];
	result.target = self;
	result.tag = aTag;
	return result;
}

- (NSMenu *)ensuredOptionsPopupMenu {
	if (!self.optionsPopupMenu) {
		self.optionsPopupMenu = ({
			NSMenu *menu = [NSMenu new];
			menu.delegate = self;
			
			// Ignore case
			// Wrap around
			// Set Scope to current selection
			// Use Regular Expressions
			// -
			// Regular Expression Dialect
			// Ruby
			// Switch Dialect >
			// -
			// Capture Groups
			// Line Context
			// Multiline
			// Extended
			// -
			// Only longest Match
			// Ignore empty matches
			// -
			// Escape Character /
			// Escape Character ¥
			// -
			// Open Regex Help
			
			
			[self addItemToMenu:menu title:@"Set Scope to current selection" action:@selector(takeScopeFromCurrentSelection:) tag:kOptionMenuSetScopeToSelectionTag];
			[self addItemToMenu:menu title:@"Ignore case" action:@selector(toggleIgnoreCase:) tag:kOptionMenuIgnoreCaseTag];
			[self addItemToMenu:menu title:@"Wrap around" action:@selector(toggleWrapAround:) tag:kOptionMenuWrapAroundTag];

			[self addItemToMenu:menu title:@"Use Regular Expressions" action:@selector(toggleUseRegex:) tag:kOptionMenuUseRegularExpressionsTag];

			[menu addItem:[NSMenuItem separatorItem]];
			[self addItemToMenu:menu title:@"Regular Expression Dialect" action:NULL tag:0];
			NSMenuItem *switchDialectMenuItem = [self addItemToMenu:menu title:@"<current selected dialect>" action:@selector(dummyAction:)	 tag:kOptionMenuSelectedLanguageDialectTag];
			[switchDialectMenuItem setSubmenu:({
				NSMenu *submenu = [NSMenu new];
				for (NSNumber *syntaxOptionNumber in @[@(OgreRubySyntax),@(OgrePerlSyntax),@(OgreJavaSyntax),@(OgreGNURegexSyntax),@(OgreGrepSyntax),@(OgreEmacsSyntax),@(OgrePOSIXExtendedSyntax),@(OgrePOSIXBasicSyntax)]) {
					OgreSyntax syntax = syntaxOptionNumber.integerValue;
					[self addItemToMenu:submenu title:[SEEFindAndReplaceState regularExpressionSyntaxStringForSyntax:syntax] action:@selector(switchRegexSyntaxDialect:) tag:syntax];
				}
				submenu;
			})];
			
			// todo: addSubmenu

			[menu addItem:[NSMenuItem separatorItem]];
			[self addItemToMenu:menu title:@"Capture unnamed groups" action:@selector(toggleRegexOption:) tag:kOptionMenuCaptureGroupsTag];
			[self addItemToMenu:menu title:@"Line context" action:@selector(toggleRegexOption:) tag:kOptionMenuLineContextTag];
			[self addItemToMenu:menu title:@"Multiline" action:@selector(toggleRegexOption:) tag:kOptionMenuMultilineTag];
			[self addItemToMenu:menu title:@"Extended" action:@selector(toggleRegexOption:) tag:kOptionMenuExtendedTag];
			

			[menu addItem:[NSMenuItem separatorItem]];
			[self addItemToMenu:menu title:@"Find only longest match" action:@selector(toggleRegexOption:) tag:kOptionMenuOnlyLongestMatchTag];
			[self addItemToMenu:menu title:@"Ignore empty matches" action:@selector(toggleRegexOption:) tag:kOptionMenuIgnoreEmptyMatchesTag];

			[menu addItem:[NSMenuItem separatorItem]];
			[self addItemToMenu:menu title:@"Escape Character: /" action:@selector(switchEscapeCharacter:) tag:kOptionMenuEscapeCharacterSlashTag];
			[self addItemToMenu:menu title:@"Escape Character: ¥" action:@selector(switchEscapeCharacter:) tag:kOptionMenuEscapeCharacterYenTag];

			[menu addItem:[NSMenuItem separatorItem]];
			[self addItemToMenu:menu title:@"Open Regular Expression Help" action:@selector(openRegExHelp:) tag:0];
			menu;
		});
	}
	return self.optionsPopupMenu;
}

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel {
	return YES;
}

#pragma mark - key value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == kOptionMenuUseRegularExpressionsTag) {
		[self updateSearchOptionsButton];
	}
}

@end
