//
//  PrecedencePreferences.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 22.09.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "PrecedencePreferences.h"
#import "DocumentController.h"
#import "GeneralPreferences.h"
#import "PrecedenceRuleCell.h"

@implementation PrecedencePreferences

- (NSImage *)icon {
    return [NSImage imageNamed:@"PrecedencePrefs"];
}

- (NSString *)iconLabel {
    return NSLocalizedString(@"PrecedencePrefsIconLabel", @"Label displayed below advanced icon and used as window title.");
}

- (NSString *)identifier {
    return @"de.codingmonkeys.subethaedit.preferences.precedence";
}

- (NSString *)mainNibName {
    return @"PrecedencePrefs";
}

- (void)mainViewDidLoad {
	[o_rulesTableView setDelegate:self];
	[o_rulesTableView setRowHeight:32];
	NSTableColumn *column = [o_rulesTableView tableColumnWithIdentifier:@"Rules"];
	[column setDataCell:[[[PrecedenceRuleCell alloc] init] autorelease]];
	ruleViews =[NSMutableDictionary new];
}

- (void)didSelect {
	//NSLog(@"%s:%d",__PRETTY_FUNCTION__,__LINE__);
}

- (void) dealloc {
    [ruleViews autorelease];
    [super dealloc];
}

- (IBAction) addUserRule:(id)sender {	
	NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
	[defaults willChangeValueForKey:@"ModePrecedences"];
	int index = [[o_rulesController arrangedObjects] count];
	//NSLog(@"foo: %@", [o_rulesController arrangedObjects]);
	[o_rulesController insertObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Placeholder",@"String",[NSNumber numberWithBool:NO],@"ModeRule",[NSNumber numberWithInt:0],@"TypeIdentifier",nil] atArrangedObjectIndex:index];
	//NSLog(@"bar: %@", [o_rulesController arrangedObjects]);
	[o_rulesController setSelectionIndex:index];
	[defaults didChangeValueForKey:@"ModePrecedences"];
}

- (IBAction) removeUserRule:(id)sender {
	NSString *key = [NSString stringWithFormat:@"%@/%d",[[[o_modesController arrangedObjects] objectAtIndex:[o_modesController selectionIndex]] objectForKey:@"Identifier"], [o_rulesController selectionIndex]];
	[o_rulesController removeObjectAtArrangedObjectIndex:[o_rulesController selectionIndex]];
	[[[ruleViews objectForKey:key] view] setHidden:YES];
	[ruleViews removeObjectForKey:key];
}

@end

@implementation PrecedencePreferences (TableViewDelegation)

- (void) tableView:(NSTableView *) tableView willDisplayCell:(id) cell forTableColumn:(NSTableColumn *) tableColumn row:(int) row {
	if (tableView != o_rulesTableView) return;
	NSDictionary *rule = [[o_rulesController arrangedObjects] objectAtIndex:row];
	
	NSString *key = [NSString stringWithFormat:@"%@/%d",[[[o_modesController arrangedObjects] objectAtIndex:[o_modesController selectionIndex]] objectForKey:@"Identifier"], row];
	//NSLog(@"rule requested: %@", rule);
	RuleViewController *ruleViewController = [ruleViews objectForKey:key];
	if (!ruleViewController) {
		//NSLog(@"Binding to: %@", rule);
		//NSLog(@"foo: %@", [cell exposedBindings]);
		ruleViewController = [[RuleViewController new] autorelease];
		//[[ruleViewController stringTextfield] bind:@"value" toObject:o_rulesController withKeyPath:@"selection.String" options:nil];
		[[ruleViewController stringTextfield] bind:@"value" toObject:rule withKeyPath:@"String" options:nil];
		[[ruleViewController stringTextfield] bind:@"editable" toObject:rule withKeyPath:@"ModeRule" options:[NSDictionary dictionaryWithObject:NSNegateBooleanTransformerName forKey:NSValueTransformerNameBindingOption]];
		[[ruleViewController typePopup] bind:@"selectedTag" toObject:rule withKeyPath:@"TypeIdentifier" options:nil];
		[[ruleViewController typePopup] bind:@"enabled" toObject:rule withKeyPath:@"ModeRule" options:[NSDictionary dictionaryWithObject:NSNegateBooleanTransformerName forKey:NSValueTransformerNameBindingOption]];
		[ruleViews setObject:ruleViewController forKey:key];
	}
		
	[[ruleViewController view] setHidden:NO];
	
	//	NSLog(@"Drawing: %@", [[ruleViewController stringTextfield] stringValue]);		
	[(PrecedenceRuleCell *)cell addSubview:[ruleViewController view]];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
	if ([aNotification object] == o_rulesTableView) return;
	
	NSEnumerator *enumerator = [ruleViews objectEnumerator];
    id object;
    while ((object = [enumerator nextObject])) {
        [[object view] setHidden:YES]; 
    }
}

@end