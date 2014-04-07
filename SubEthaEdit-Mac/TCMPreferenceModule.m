//
//  TCMPreferenceModule.m
//  SubEthaEdit
//
//  Created by Martin Ott on Thu Feb 26 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMPreferenceModule.h"

@interface TCMPreferenceModule ()

@property (readwrite, strong) NSArray *topLevelNibObjects;

@end

@implementation TCMPreferenceModule

- (void)dealloc
{
	self.topLevelNibObjects = nil;
	self.O_window = nil;

    [super dealloc];
}

- (NSImage *)icon
{
    return nil;
}

- (NSString *)iconLabel
{
    return nil;
}

- (NSString *)identifier
{
    return nil;
}

- (NSView *)assignMainView
{
    NSView *contentView = [self.O_window contentView];
    if (NSResizableWindowMask & [self.O_window styleMask]) {
        I_minSize = [self.O_window contentMinSize];
        I_maxSize = [self.O_window contentMaxSize];
    } else {
        I_minSize = I_maxSize = [[self.O_window contentView] frame].size;
    }
    [self setMainView:contentView];
    self.O_window = nil;
    
    return contentView;
}

- (NSString *)mainNibName
{
    return @"Main";
}

- (NSView *)loadMainView
{
    // Determines the name of the main nib file by calling the preference pane objectmainNibName method.
    NSString *mainNibName = [self mainNibName];

    // Loads that nib file, passing in the preference pane object as the nib file's owner.
	NSArray *topLevelNibObjects = nil;
    [[NSBundle mainBundle] loadNibNamed:mainNibName owner:self topLevelObjects:&topLevelNibObjects];
	self.topLevelNibObjects = topLevelNibObjects;

    // Invokes the preference pane object assignMainView method to find and assign the main view.
    NSView *mainView = [self assignMainView];
    
    // Invokes the preference pane object mainViewDidLoad method.
    [self mainViewDidLoad];

    // Returns the main view.
    return mainView;
}

- (NSView *)mainView
{
    return O_mainView;
}

- (void)mainViewDidLoad
{
}

- (void)setMainView:(NSView *)aView
{
    [O_mainView autorelease];
    O_mainView = [aView retain];
}

- (void)didSelect
{
}

- (void)willSelect
{
}

- (void)didUnselect
{
}

- (void)replyToShouldUnselect:(BOOL)shouldUnselect
{
}

- (NSPreferencePaneUnselectReply)shouldUnselect
{
    return NSUnselectNow;
}

- (void)willUnselect
{
}

- (NSSize)maxSize
{
    return I_maxSize;
}

- (NSSize)minSize
{
    return I_minSize;
}

@end
