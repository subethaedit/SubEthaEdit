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
		preferenceController = nil;
    }
    return self;
}

- (void) dealloc
{
    [view setHidden:YES];    
    [view release];
	[preferenceController release];
	[rule release];
    [super dealloc];
}

- (void)setPreferenceController:(PrecedencePreferences*)controller {
	preferenceController = [controller retain];
}

- (void)setRule:(NSMutableDictionary *)dict {
	[rule autorelease];
	rule = [dict retain];
}

- (NSMutableDictionary *)rule {
	return rule;
}

-(IBAction)valuesChanged:(id)sender{
	[[DocumentModeManager sharedInstance] revalidatePrecedences];
}

-(IBAction)removeRule:(id)sender {
	[preferenceController removeUserRule:self];
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

- (NSButton *) removeButton {
	return removeButton;
}

@end