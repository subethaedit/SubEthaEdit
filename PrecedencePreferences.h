//
//  PrecedencePreferences.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 22.09.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCMPreferenceModule.h"


@interface PrecedencePreferences : TCMPreferenceModule {
	IBOutlet NSView *o_precedenceView;
	IBOutlet NSTableView *o_rulesTableView;
	IBOutlet NSArrayController *o_modesController;
	IBOutlet NSArrayController *o_rulesController;
	NSMutableDictionary *ruleViews;
}

- (IBAction) addUserRule:(id)sender;
- (IBAction) removeUserRule:(id)sender;


@end
