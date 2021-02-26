//  PrecedenceRuleCell.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 22.09.07.

#import <Cocoa/Cocoa.h>
#import "PrecedencePreferences.h"


@interface PrecedenceRuleCell : NSCell
@property (nonatomic, strong) IBOutlet NSView *view;
@end


@interface RuleViewController : NSObject
@property (nonatomic, strong) IBOutlet NSView *view;
@property (nonatomic, strong) IBOutlet NSButton *enabledCheckbox;
@property (nonatomic, strong) IBOutlet NSButton *removeButton;
@property (nonatomic, strong) IBOutlet NSPopUpButton *typePopup;
@property (nonatomic, strong) IBOutlet NSTextField *stringTextfield;
@property (nonatomic, strong) IBOutlet NSImageView *warningImageView;
@property (nonatomic, strong) NSMutableDictionary *rule;

- (IBAction)valuesChanged:(id)sender;
- (IBAction)removeRule:(id)sender;
- (IBAction)addRule:(id)sender;
- (void)setPreferenceController:(PrecedencePreferences *)controller;
@end
