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


@interface TCMPreferenceController (TCMPreferenceControllerPrivateAdditions)

- (void)switchPrefPane:(id)aSender;
- (NSString *)selectedItemIdentifier;
- (void)setSelectedItemIdentifier:(NSString *)anIdentifier;
- (NSView *)contentView;
- (void)setContentView:(NSView *)aView;
- (void)selectPrefPaneWithIdentifier:(NSString *)anIdentifier;

@end


@implementation TCMPreferenceController

+ (void)initialize
{
    registeredPrefModules = [NSMutableDictionary new];
}

+ (void)registerPrefModule:(TCMPreferenceModule *)aModule
{
    [registeredPrefModules setObject:aModule forKey:[aModule iconLabel]];
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
    [super init];
}

- (void)awakeFromNib
{
}

- (void)windowWillLoad
{
    NSEnumerator *modules = [registeredPrefModules objectEnumerator];
    TCMPreferenceModule *module;
    while ((module = [modules nextObject])) {
        NSString *itemIdent = [module iconLabel];
        [I_toolbarItemIdentifiers addObject:itemIdent];    
    }
    
    I_toolbar = [[NSToolbar alloc] initWithIdentifier:@"Preferences Toolbar Identifier"];
    [I_toolbar setAutosavesConfiguration:NO];
    [I_toolbar setDelegate:self];
}

- (NSView *)contentView
{
    return I_contentView;
}

- (void)setContentView:(NSView *)aView
{
    [I_contentView autorelease];
    I_contentView = [aView retain];
}

- (void)windowDidLoad
{
    [[self window] setToolbar:I_toolbar];
    [I_toolbar autorelease];
        
    NSString *identifier = [I_toolbarItemIdentifiers objectAtIndex:0];
    [I_toolbar setSelectedItemIdentifier:identifier];
    
    [self setContentView:[[self window] contentView]];
    [self selectPrefPaneWithIdentifier:identifier];
}

- (void)selectPrefPaneWithIdentifier:(NSString *)anIdentifier
{
    NSWindow *window = [self window];
    [window setContentView:[self contentView]];

    [self setSelectedItemIdentifier:anIdentifier];
    TCMPreferenceModule *module = [registeredPrefModules objectForKey:anIdentifier];
    if ([module mainView] == nil) {
        if (![module loadMainView]) {
            DEBUGLOG(@"Preferences", 1, @"loadMainView failed: %@", module);
        }
    }
    
    [module willSelect];

    [window setTitle:[module iconLabel]];
    
    NSRect frame;
    frame = [window contentRectForFrameRect:[window frame]];
    frame.origin.y += frame.size.height;
    frame.origin.y -= [[module mainView] bounds].size.height;
    frame.size.height = [[module mainView] bounds].size.height;
    frame.size.width = [[module mainView] bounds].size.width;
    frame = [window frameRectForContentRect:frame];
    [window setFrame:frame display:YES animate:YES];

    [[self window] setContentView:[module mainView]];

    [module didSelect];
}

- (void)switchPrefPane:(id)aSender
{
    NSString *identifier = [I_toolbar selectedItemIdentifier];
    
    NSString *previousIdentifier = [self selectedItemIdentifier];
    if (previousIdentifier) {
        id prefPane = [registeredPrefModules objectForKey:previousIdentifier];
        NSPreferencePaneUnselectReply reply = [prefPane shouldUnselect];
        if (reply == NSUnselectNow) {
            [prefPane willUnselect];
            [self selectPrefPaneWithIdentifier:identifier];
            [prefPane didUnselect];
        } else {
            NSLog(@"NOT YET IMPLEMENTED");
        }
    } else {
    }
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

- (void)windowWillClose:(NSNotification *)aNotification
{
}

#pragma mark -

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted
{
    id module = [registeredPrefModules objectForKey:itemIdent];
    if (module) {
        NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdent] autorelease];
        [toolbarItem setLabel:[module iconLabel]];
        [toolbarItem setImage:[module icon]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(switchPrefPane:)];
        
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
