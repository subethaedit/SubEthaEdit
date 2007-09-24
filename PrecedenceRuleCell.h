//
//  PrecedenceRuleCell.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 22.09.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PrecedenceRuleCell : NSCell {
	NSView *subview;
}
- (void) addSubview:(NSView *) view;
@end

@interface RuleViewController : NSObject {
	IBOutlet NSView *view;
	IBOutlet NSButton *enabledCheckbox;
	IBOutlet NSPopUpButton *typePopup;
	IBOutlet NSTextField *stringTextfield;
	IBOutlet NSImageView *warningImageView;
}
- (NSView *) view;
- (NSButton *) enabledCheckbox;
- (NSPopUpButton *) typePopup;
- (NSTextField *) stringTextfield;
- (NSImageView *) warningImageView;
	
@end
