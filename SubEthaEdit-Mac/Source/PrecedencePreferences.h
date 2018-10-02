//  PrecedencePreferences.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 22.09.07.

#import <Cocoa/Cocoa.h>
#import "TCMPreferenceModule.h"


@interface PrecedencePreferences : TCMPreferenceModule <NSTableViewDelegate> {
	IBOutlet NSTableView *o_rulesTableView;
	IBOutlet NSArrayController *o_modesController;
	IBOutlet NSArrayController *o_rulesController;
	NSMutableDictionary *ruleViews;
}

- (IBAction) addUserRule:(id)sender;
- (IBAction) removeUserRule:(id)sender;


@end
