//
//  PlainTextWindowController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Mar 05 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "PlainTextWindowController.h"


NSString * const PlainTextWindowToolbarIdentifier = @"PlainTextWindowToolbarIdentifier";
NSString * const ParticipantsToolbarItemIdentifier = @"ParticipantsToolbarItemIdentifier";


@implementation PlainTextWindowController

- (id)init {
    if ((self=[super initWithWindowNibName:@"PlainTextWindow"])) {
    
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void)windowWillLoad {
    if ([self document]) {
        [[self document] windowControllerWillLoadNib:self];
    }
}

- (void)windowDidLoad {
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:PlainTextWindowToolbarIdentifier] autorelease];
    
    [toolbar setAllowsUserCustomization:YES];
    //[toolbar setAutosavesConfiguration:YES];
    [toolbar setDelegate:self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar:toolbar];
    
    if ([self document]) {
        [[self document] windowControllerDidLoadNib:self];
    }
}

#pragma mark -

- (IBAction)toggleDrawer:(id)sender {
    //[oPeopleDrawer toggle:aSender];
}

#pragma mark -

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted {

    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    
    if ([itemIdent isEqualToString:ParticipantsToolbarItemIdentifier]) {
        [toolbarItem setLabel:@"Participants"];
        [toolbarItem setPaletteLabel:@"Participants"];
        [toolbarItem setToolTip:@"Participants"];
        [toolbarItem setImage:[NSImage imageNamed:@"Participants"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(toggleDrawer:)];
    } else {
        toolbarItem = nil;
    }
    
    return toolbarItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:
                NSToolbarFlexibleSpaceItemIdentifier,
                ParticipantsToolbarItemIdentifier,
                nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:
                ParticipantsToolbarItemIdentifier,
                NSToolbarPrintItemIdentifier,
                NSToolbarCustomizeToolbarItemIdentifier,
                NSToolbarSeparatorItemIdentifier,
                NSToolbarSpaceItemIdentifier,
                NSToolbarFlexibleSpaceItemIdentifier,
                nil];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem {
    return YES;
}

@end
