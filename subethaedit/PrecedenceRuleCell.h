//
//  PrecedenceRuleCell.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 22.09.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrecedencePreferences.h"


@interface PrecedenceRuleCell : NSCell {
	NSView *subview;
}
- (void) addSubview:(NSView *) view;
@end

@interface RuleViewController : NSObject {
	IBOutlet NSView *view;
	IBOutlet NSButton *enabledCheckbox;
	IBOutlet NSButton *removeButton;
	IBOutlet NSPopUpButton *typePopup;
	IBOutlet NSTextField *stringTextfield;
	IBOutlet NSImageView *warningImageView;
	PrecedencePreferences* preferenceController;
	NSMutableDictionary* rule;
}
- (NSView *) view;
- (NSButton *) enabledCheckbox;
- (NSPopUpButton *) typePopup;
- (NSTextField *) stringTextfield;
- (NSImageView *) warningImageView;
- (NSButton *) removeButton;
-(IBAction)valuesChanged:(id)sender;
-(IBAction)removeRule:(id)sender;
- (void)setPreferenceController:(PrecedencePreferences*)controller;
- (void)setRule:(NSMutableDictionary *)dict;
- (NSMutableDictionary *)rule;
	
@end
