//
//  PrecedenceRuleCell.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 22.09.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "PrecedenceRuleCell.h"
#import "DocumentModeManager.h"


@implementation PrecedenceRuleCell
- (void) addSubview:(NSView *) view {
    subview = view;
}

- (void) dealloc {
    subview = nil;
    [super dealloc];
}

- (NSView *) view {
    return subview;
}

- (void) drawWithFrame:(NSRect) cellFrame inView:(NSView *) controlView
{
    [super drawWithFrame: cellFrame inView: controlView];
    [[self view] setFrame: cellFrame];
	
    if ([[self view] superview] != controlView) {
		[controlView addSubview: [self view]];
    }
}

- (void)setPlaceholderString:(NSString *)string {
	
}

@end

@implementation RuleViewController
- (id)init {
    self = [super init];
    if (self) {
		[NSBundle loadNibNamed: @"PrecedenceRules" owner: self];
    }
    return self;
}

- (void) dealloc
{
    [view setHidden:YES];    
    [view release];    
    [super dealloc];
}

-(IBAction)valuesChanged:(id)sender{
	[[DocumentModeManager sharedInstance] revalidatePrecedences];
}


- (NSView *) view {
	return view;
}
- (NSButton *) enabledCheckbox {
	return enabledCheckbox;
}
- (NSPopUpButton *) typePopup {
	return typePopup;
}
- (NSTextField *) stringTextfield {
	return stringTextfield;
}
- (NSImageView *) warningImageView {
	return warningImageView;
}

- (NSImageView *) removeButton {
	return removeButton;
}

@end