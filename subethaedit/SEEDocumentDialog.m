//
//  SEEDocumentDialog.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 11.09.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "SEEDocumentDialog.h"


@implementation SEEDocumentDialog

- (void)dealloc {
    [O_mainView release];
    [I_topLevelNibObjects release];
    [super dealloc];
}

- (NSView *)assignMainView
{
    NSView *contentView = [O_window contentView];
    if (NSResizableWindowMask & [O_window styleMask]) {
        I_minSize = [O_window contentMinSize];
        I_maxSize = [O_window contentMaxSize];
    } else {
        I_minSize = I_maxSize = [[O_window contentView] frame].size;
    }
    [self setMainView:contentView];
    
    return contentView;
}

- (NSString *)mainNibName
{
    return @"Main";
}

- (NSView *)loadMainView
{
    // Determines the name of the main nib file by calling the preference pane object’s mainNibName method.
    NSString *mainNibName = [self mainNibName];

    // Loads that nib file, passing in the preference pane object as the nib file’s owner.

    [[[[NSNib alloc] initWithNibNamed:mainNibName bundle:nil] autorelease] instantiateNibWithOwner:self topLevelObjects:&I_topLevelNibObjects];
    [I_topLevelNibObjects retain];
    [I_topLevelNibObjects makeObjectsPerformSelector:@selector(release)];

    // Invokes the preference pane object’s assignMainView method to find and assign the main view.
    NSView *mainView = [self assignMainView];
    
    // Invokes the preference pane object’s mainViewDidLoad method.
    [self mainViewDidLoad];

    // Returns the main view.
    return mainView;
}

- (NSView *)mainView
{
    if (!O_mainView) [self loadMainView];
    return O_mainView;
}

- (void)setMainView:(NSView *)aView
{
    [O_mainView autorelease];
     O_mainView = [aView retain];
}

- (void)mainViewDidLoad
{
}

- (id)document {
    return I_document;
}

- (void)setDocument:(id)aDocument
{
     I_document = aDocument;
}



@end
