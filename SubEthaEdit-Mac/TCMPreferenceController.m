//
//  TCMPreferenceController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Thu Feb 26 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMPreferenceController.h"
#import "TCMPreferenceModule.h"


static NSMutableDictionary *registeredPrefModules;
static NSMutableArray *prefModules;


@interface TCMPreferenceController (TCMPreferenceControllerPrivateAdditions)

- (void)switchPrefPane:(id)aSender;
- (NSString *)selectedItemIdentifier;
- (void)setSelectedItemIdentifier:(NSString *)anIdentifier;
- (NSView *)emptyContentView;
- (void)setEmptyContentView:(NSView *)aView;
- (void)selectPrefPaneWithIdentifier:(NSString *)anIdentifier;
- (id)selectedModule;
@end

#pragma mark -

static TCMPreferenceController *sharedInstance = nil;

@implementation TCMPreferenceController

+ (TCMPreferenceController *)sharedInstance
{
    return sharedInstance;
}

+ (void)initialize
{
	if (self == [TCMPreferenceController class]) {
		prefModules = [NSMutableArray new];
		registeredPrefModules = [NSMutableDictionary new];
	}
}

+ (void)registerPrefModule:(TCMPreferenceModule *)aModule
{
    [prefModules addObject:aModule];
    [registeredPrefModules setObject:aModule forKey:[aModule identifier]];
}

- (id)init
{
    self = [super initWithWindowNibName:@"Preferences"];
    if (self) {
        I_toolbarItemIdentifiers = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc
{
    [I_toolbarItemIdentifiers release];
    [I_selectedItemIdentifier release];
    [super dealloc];
}

- (void)awakeFromNib
{    
    sharedInstance = self;
}

- (void)windowWillLoad
{
    TCMPreferenceModule *module;
    for (module in prefModules) {
        NSString *itemIdent = [module identifier];
        [I_toolbarItemIdentifiers addObject:itemIdent];    
    }
    
    I_toolbar = [[NSToolbar alloc] initWithIdentifier:@"Preferences Toolbar Identifier"];
    [I_toolbar setAutosavesConfiguration:NO];
    [I_toolbar setAllowsUserCustomization:NO];
    [I_toolbar setDelegate:self];
}

- (NSView *)emptyContentView
{
    return I_emptyContentView;
}

- (void)setEmptyContentView:(NSView *)aView
{
    [I_emptyContentView autorelease];
    I_emptyContentView = [aView retain];
}

- (void)windowDidLoad
{
    [[self window] setToolbar:I_toolbar];
    [[[self window] standardWindowButton: NSWindowToolbarButton] setFrame: NSZeroRect];

    [I_toolbar autorelease];
        
    if ([I_toolbarItemIdentifiers count] > 0) {
        NSString *identifier = [I_toolbarItemIdentifiers objectAtIndex:0];
        [I_toolbar setSelectedItemIdentifier:identifier];
        
        [self setEmptyContentView:[[self window] contentView]];
        
        id module = [registeredPrefModules objectForKey:identifier];
        [module willSelect];
        [self setSelectedItemIdentifier:identifier];
        [self selectPrefPaneWithIdentifier:identifier];
        [module didSelect];
    }
    [[self window] setDelegate:self];
}


// update on show of window
- (void)windowWillClose:(NSNotification *)aNotification {
	didShow = NO;
}

- (void)windowDidBecomeMain:(NSNotification *)anotification {
	if (!didShow) {
		didShow = YES;
		[[self selectedModule] didSelect];
	}
}

- (void)selectPrefPaneWithIdentifier:(NSString *)anIdentifier
{
    NSWindow *window = [self window];
    [window setContentView:[self emptyContentView]];

    id module = [registeredPrefModules objectForKey:anIdentifier];
    if ([module mainView] == nil) {
        if (![module loadMainView]) {
            //NSLog(@"loadMainView failed: %@", module);
            return;
        }
    }
    
    [window setTitle:[module iconLabel]];
    
    NSRect frame;
    frame = [window contentRectForFrameRect:[window frame]];
    frame.origin.y += frame.size.height;
    frame.origin.y -= [[module mainView] bounds].size.height;
    frame.size.height = [[module mainView] bounds].size.height;
    frame.size.width = [[module mainView] bounds].size.width;
    frame = [window frameRectForContentRect:frame];
    [window setFrame:frame display:YES animate:YES];

    [window setContentView:[module mainView]];
    if ([module isKindOfClass:[NSResponder class]]) {
        [self setNextResponder:module];
    } else {
        [self setNextResponder:nil];
    }
    
    if ([module isKindOfClass:[TCMPreferenceModule class]]) {
        [window setContentMaxSize:[module maxSize]];
        [window setContentMinSize:[module minSize]];
        if (NSEqualSizes([module maxSize], [module minSize])) {
            [window setShowsResizeIndicator:NO];
        } else {
            [window setShowsResizeIndicator:YES];
        }
    } else {
        [window setShowsResizeIndicator:YES];
    }
}

- (void)selectPrefPane:(id)aSender
{
    NSString *identifier = [I_toolbar selectedItemIdentifier];
    NSString *previousIdentifier = [self selectedItemIdentifier];

    if ([identifier isEqualToString:previousIdentifier]) {
        return;
    }
    
    id prefPane = [registeredPrefModules objectForKey:previousIdentifier];
    NSPreferencePaneUnselectReply reply = [prefPane shouldUnselect];
    if (reply == NSUnselectNow) {
        [prefPane willUnselect];
        id module = [registeredPrefModules objectForKey:identifier];
        [module willSelect];
        [self setSelectedItemIdentifier:identifier];
        [prefPane didUnselect];
        [self selectPrefPaneWithIdentifier:identifier];
        [module didSelect];
    }
}

- (id)selectedModule 
{
    return [registeredPrefModules objectForKey:[self selectedItemIdentifier]];
}

- (NSString *)selectedItemIdentifier
{
    return I_selectedItemIdentifier;
}

- (void)setSelectedItemIdentifier:(NSString *)anIdentifier
{
    [I_selectedItemIdentifier autorelease];
    I_selectedItemIdentifier = [anIdentifier copy];   
}

- (BOOL)windowShouldClose:(id)sender
{
    BOOL shouldClose = YES;
    
    id module = [registeredPrefModules objectForKey:[self selectedItemIdentifier]];
    if (module) {
        NSPreferencePaneUnselectReply reply = [module shouldUnselect];
        if (reply == NSUnselectNow) {
            [module willUnselect];
            [module didUnselect];
        } else if (reply == NSUnselectCancel) {
            shouldClose = NO;
        }
    }
    
    return shouldClose;
}

#pragma mark -

- (BOOL)selectPreferenceModuleWithIdentifier:(NSString *)identifier
{
    if (![[self window] attachedSheet]) {
        [I_toolbar setSelectedItemIdentifier:identifier];
        [self selectPrefPane:self];
        if ([[self window] attachedSheet]) {
            NSBeep();
            return NO;
        }
    } else {
        NSBeep();
        return NO;
    }

    return YES;
}

- (TCMPreferenceModule *)preferenceModuleWithIdentifier:(NSString *)identifier
{
    return [registeredPrefModules objectForKey:identifier];
}

#pragma mark - NSToolbarDelegate

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted
{
    id module = [registeredPrefModules objectForKey:itemIdent];
    if (module) {
        NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdent] autorelease];
        [toolbarItem setLabel:[module iconLabel]];
        [toolbarItem setImage:[module icon]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(selectPrefPane:)];
        
        return toolbarItem;
    }
        
    return nil;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return I_toolbarItemIdentifiers;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return I_toolbarItemIdentifiers;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    return I_toolbarItemIdentifiers;
}

@end
