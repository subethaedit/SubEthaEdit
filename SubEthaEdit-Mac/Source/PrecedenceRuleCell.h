//  PrecedenceRuleCell.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 22.09.07.

#import <Cocoa/Cocoa.h>
#import "PrecedencePreferences.h"


@interface PrecedenceRuleCell : NSCell {
	NSView *subview;
}
- (void) addSubview:(NSView *) view;
@end

@interface RuleViewController : NSObject {
	PrecedencePreferences* preferenceController;
	NSMutableDictionary* rule;
}

@property (readwrite, strong) IBOutlet NSView *view;
@property (readwrite, assign) IBOutlet NSButton *enabledCheckbox;
@property (readwrite, assign) IBOutlet NSButton *removeButton;
@property (readwrite, assign) IBOutlet NSPopUpButton *typePopup;
@property (readwrite, assign) IBOutlet NSTextField *stringTextfield;
@property (readwrite, assign) IBOutlet NSImageView *warningImageView;

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
