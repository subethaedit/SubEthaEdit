//
//  SEEFindAndReplaceViewController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 24.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import "SEEFindAndReplaceViewController.h"
#import "FindReplaceController.h"
#import "PlainTextWindowController.h"
#import "PlainTextEditor.h"
#import "PlainTextWindowControllerTabContext.h"
#import "SEETextView.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

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


@interface SEEFindAndReplaceViewController () <NSMenuDelegate>
@property (nonatomic, strong) NSMenu *optionsPopupMenu;
@property (nonatomic, strong) NSMutableSet *registeredNotifications;
@property (nonatomic, readonly) SEETextView *targetTextView;
@property (nonatomic, readonly) PlainTextEditor *targetPlainTextEditor;
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
	for (id element in @[self.findTextField, self.replaceTextField, self.findPreviousButton, self.findNextButton, self.replaceButton,self.replaceAllButton,self.searchOptionsButton, self.findAllButton]) {
		[element setEnabled:isEnabled];
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
	NSImage *image = [NSImage pdfBasedImageNamed:@"SearchLoupeNormal"TCM_PDFIMAGE_SEP@"36"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_NORMAL];
	if ([[self.findAndReplaceStateObjectController valueForKeyPath:kOptionKeyPathUseRegularExpressions] boolValue]) {
		image = [NSImage pdfBasedImageNamed:@"SearchLoupeRE"TCM_PDFIMAGE_SEP@"36"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_NORMAL];
	}

	[self.searchOptionsButton setImage:image];

	NSShadow *shadow = nil;
	if (self.hasSearchScope) {
		shadow = [NSShadow new];
		[shadow setShadowColor:[NSColor searchScopeBaseColor]];
		[shadow setShadowOffset:NSMakeSize(0, 0)];
		[shadow setShadowBlurRadius:10.0];
	}
	[self.searchOptionsButton setShadow:shadow];
}

- (BOOL)hasSearchScope {
	BOOL result = nil;
	PlainTextEditor *targetEditor = self.targetPlainTextEditor;
	result = [targetEditor hasSearchScope];
	return result;
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
	[self.feedbackTextField bind:@"value" toObject:self.findAndReplaceStateObjectController withKeyPath:@"content.statusString" options:nil];
	
	// add observation
	[self.findAndReplaceStateObjectController addObserver:self forKeyPath:kOptionKeyPathUseRegularExpressions options:0 context:kOptionMenuUseRegularExpressionsTag];
	
	__weak __typeof__(self) weakSelf = self;
	[self.registeredNotifications addObject:[[NSNotificationCenter defaultCenter] addObserverForName:PlainTextEditorDidChangeSearchScopeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		[weakSelf updateSearchOptionsButton];
	}]];

	[self.registeredNotifications addObject:[[NSNotificationCenter defaultCenter] addObserverForName:SEEPlainTextWindowControllerTabContextActiveEditorDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		[note.object isEqual:self.plainTextWindowControllerTabContext];
		[weakSelf updateSearchOptionsButton];
	}]];
}

- (NSObjectController *)findAndReplaceStateObjectController {
	return [FindReplaceController sharedInstance].globalFindAndReplaceStateController;
}

- (IBAction)findAndReplaceAction:(id)aSender {
	[[FindReplaceController sharedInstance] performFindPanelAction:aSender inTargetTextView:self.targetTextView];
}


- (IBAction)dismissAction:(id)sender {
	// this is a little bit bad because it knows about the first plain text editor being the one displaying us
	[self.plainTextWindowControllerTabContext.plainTextEditors.firstObject findAndReplaceViewControllerDidPressDismiss:self];
}

- (IBAction)searchOptionsDropdownAction:(id)sender {
	NSMenu *menu = [self ensuredOptionsPopupMenu];
	[menu popUpMenuPositioningItem:nil atLocation:({ NSPoint result = NSZeroPoint;
		result.y = NSMaxY(self.searchOptionsButton.bounds);
		result;}) inView:self.searchOptionsButton];
	
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
	//	NSLog(@"%s menuItem:%@",__FUNCTION__,menuItem);
	
	BOOL useRegex = [[self.findAndReplaceStateObjectController valueForKeyPath:kOptionKeyPathUseRegularExpressions] boolValue];
	BOOL validationResultForRegexOptions = useRegex;
	
	if (menuItem.action == @selector(clearSearchScope:)) {
		if (![self hasSearchScope]) {
			return NO;
		}
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
						
			
			[self addItemToMenu:menu title:@"Clear Scope" action:@selector(clearSearchScope:) tag:kOptionMenuClearScopeTag];
			[self addItemToMenu:menu title:@"Add current selection to Scope" action:@selector(addCurrentSelectionToSearchScope:) tag:kOptionMenuAddSelectionToSearchScopeTag];
			[menu addItem:[NSMenuItem separatorItem]];
			[self addItemToMenu:menu title:@"Ignore case" action:@selector(toggleIgnoreCase:) tag:kOptionMenuIgnoreCaseTag];
			[self addItemToMenu:menu title:@"Wrap around" action:@selector(toggleWrapAround:) tag:kOptionMenuWrapAroundTag];

			[menu addItem:[NSMenuItem separatorItem]];
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
				[submenu addItem:[NSMenuItem separatorItem]];
				[self addItemToMenu:submenu title:@"Extended" action:@selector(toggleRegexOption:) tag:kOptionMenuExtendedTag];
				[submenu addItem:[NSMenuItem separatorItem]];
				[self addItemToMenu:submenu title:@"Escape Character: \\" action:@selector(switchEscapeCharacter:) tag:kOptionMenuEscapeCharacterSlashTag];
				[self addItemToMenu:submenu title:@"Escape Character: ¥" action:@selector(switchEscapeCharacter:) tag:kOptionMenuEscapeCharacterYenTag];

				
				submenu;
			})];
			
			// todo: addSubmenu

			[menu addItem:[NSMenuItem separatorItem]];
			[self addItemToMenu:menu title:@"Capture unnamed groups" action:@selector(toggleRegexOption:) tag:kOptionMenuCaptureGroupsTag];
			[self addItemToMenu:menu title:@"Line context" action:@selector(toggleRegexOption:) tag:kOptionMenuLineContextTag];
			[self addItemToMenu:menu title:@"Multiline" action:@selector(toggleRegexOption:) tag:kOptionMenuMultilineTag];
			

			[menu addItem:[NSMenuItem separatorItem]];
			[self addItemToMenu:menu title:@"Find only longest match" action:@selector(toggleRegexOption:) tag:kOptionMenuOnlyLongestMatchTag];
			[self addItemToMenu:menu title:@"Ignore empty matches" action:@selector(toggleRegexOption:) tag:kOptionMenuIgnoreEmptyMatchesTag];


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
	if (context == (void *)kOptionMenuUseRegularExpressionsTag) {
		[self updateSearchOptionsButton];
	}
}

@end
