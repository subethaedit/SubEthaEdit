//
//  TCMPreferenceController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Thu Feb 26 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMPreferenceController.h"
#import "TCMPreferenceModule.h"


static NSMutableArray *registeredPrefModules;


@implementation TCMPreferenceController

+ (void)initialize
{
    registeredPrefModules = [NSMutableArray new];
}

+ (void)registerPrefModule:(TCMPreferenceModule *)aModule
{
    [registeredPrefModules addObject:aModule];
}

- (id)init
{
    self = [super initWithWindowNibName:@"Preferences"];
    if (self) {
        I_toolbarItems = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc
{
    [I_toolbarItems release];
    [super init];
}

- (void)awakeFromNib
{
    I_toolbar = [[NSToolbar alloc] initWithIdentifier:@"Preferences Toolbar Identifier"];
    [I_toolbar setAutosavesConfiguration:NO];
    [I_toolbar setDelegate:self];
}

- (void)windowWillLoad
{
    NSEnumerator *modules = [registeredPrefModules objectEnumerator];
    TCMPreferenceModule *module;
    while ((module = [modules nextObject])) {
        NSString *itemIdent = [module iconLabel];
        
        NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdent] autorelease];
        
        [toolbarItem setLabel:[module iconLabel]];
        [toolbarItem setImage:[module icon]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(switchPrefPane:)];
        
        [I_toolbarItems setObject:toolbarItem forKey:itemIdent];    
    }
}

- (void)windowDidLoad
{
    [[self window] setFrameAutosaveName:@"Preferences"];
    [[self window] setToolbar:I_toolbar];
    [I_toolbar autorelease];
}

- (void)switchPrefPane:(id)aSender
{
}

#pragma mark -

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted
{
    return [I_toolbarItems objectForKey:itemIdent];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return [I_toolbarItems allKeys];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [I_toolbarItems allKeys];
}

@end
