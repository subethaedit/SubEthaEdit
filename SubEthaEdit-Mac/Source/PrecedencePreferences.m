//  PrecedencePreferences.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 22.09.07.

#import "PrecedencePreferences.h"
#import "SEEDocumentController.h"
#import "GeneralPreferences.h"
#import "PrecedenceRuleCell.h"
#import "DocumentModeManager.h"

@implementation PrecedencePreferences {
    IBOutlet NSTableView *o_rulesTableView;
    IBOutlet NSArrayController *o_modesController;
    IBOutlet NSArrayController *o_rulesController;
    NSMutableDictionary *ruleViews;
}

- (NSImage *)icon {
    if (@available(macOS 10.16, *)) {
        return [NSImage imageWithSystemSymbolName:@"bolt.horizontal" accessibilityDescription:nil];
    } else {
        return [NSImage imageNamed:@"PrefIconTrigger"];
    }
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
    [self localizeLayout];
	[o_rulesTableView setDelegate:self];
	[o_rulesTableView setRowHeight:32];
    [o_rulesTableView deselectAll:nil];
    o_rulesTableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
	NSTableColumn *column = [o_rulesTableView tableColumnWithIdentifier:@"Rules"];
	[column setDataCell:[[PrecedenceRuleCell alloc] init]];
	ruleViews = [NSMutableDictionary new];
}

- (void)didSelect {
	//NSLog(@"%s:%d",__PRETTY_FUNCTION__,__LINE__);
}

- (IBAction)addUserRule:(id)sender {
	int index = [[o_rulesController arrangedObjects] count];
	//NSLog(@"foo: %@", [o_rulesController arrangedObjects]);
	NSMutableDictionary *newRule =
    [@{
       @"String"           :@"",
       @"ModeRule"         :@NO,
       @"TypeIdentifier"   :@0,
       @"Enabled"          :@YES,
       @"Overridden"       :@NO,
       @"OverriddenTooltip":@"",
       } mutableCopy];

	// NSLog(@"%s %@ %d",__FUNCTION__, newRule,(int)newRule);
	[o_rulesController insertObject:newRule atArrangedObjectIndex:index];
	//NSLog(@"bar: %@", [o_rulesController arrangedObjects]);
	//[o_rulesController setSelectionIndex:index];
	[[DocumentModeManager sharedInstance] revalidatePrecedences];
    [o_rulesTableView deselectAll:nil];
	[o_rulesTableView scrollRowToVisible:index];
}

- (IBAction)removeUserRule:(id)sender {
	RuleViewController *ruleViewController = sender;
	[[ruleViewController view] setHidden:YES];
	int i;
	for (i=0;i<[[o_rulesController arrangedObjects] count];i++){
		if ((intptr_t)[[o_rulesController arrangedObjects] objectAtIndex:i] == (intptr_t)[sender rule]) {
			[o_rulesController removeObjectAtArrangedObjectIndex:i];
			break;
		}
	}
	NSString *key = [NSString stringWithFormat:@"%li", (intptr_t)[sender rule]];
	[ruleViews removeObjectForKey:key];
	[[DocumentModeManager sharedInstance] revalidatePrecedences];
    [o_rulesTableView deselectAll:nil];
//	[o_rulesTableView setNeedsDisplay:YES];
}

- (void)localizeLayout {
    NSArray *array = [NSLocale preferredLanguages];
    NSString *firstChoice = [array firstObject];
    if ([firstChoice isEqualToString:@"de"] || [firstChoice isEqualToString:@"German"]) {
        // re-layout for German
        NSRect frame = self.mainView.window.frame;
        NSSize newSize = CGSizeMake(frame.size.width, frame.size.height + 14);
        frame.origin.y -= frame.size.height;
        frame.origin.y += newSize.height;
        frame.size = newSize;
        [self.mainView.window setFrame:frame display:NO];
    }
}


@end

@implementation PrecedencePreferences (TableViewDelegation)

- (void)tableView:(NSTableView *) tableView willDisplayCell:(id) cell forTableColumn:(NSTableColumn *) tableColumn row:(NSInteger) row {
	if (tableView != o_rulesTableView) return;
	NSMutableDictionary *rule = [[o_rulesController arrangedObjects] objectAtIndex:row];
	//NSLog(@"%s %@ %d",__FUNCTION__, rule, (int)rule);
	
	NSString *key = [NSString stringWithFormat:@"%li", (intptr_t)rule];
	//NSLog(@"rule requested: %@", rule);
	RuleViewController *ruleViewController = [ruleViews objectForKey:key];
	if (!ruleViewController) {
		//NSLog(@"Binding to: %@", rule);
		//NSLog(@"foo: %@", [cell exposedBindings]);
		ruleViewController = [RuleViewController new];
		[ruleViewController setPreferenceController:self];
		[ruleViewController setRule:rule];
		[[ruleViewController stringTextfield] bind:@"value" toObject:rule withKeyPath:@"String" options:nil];
		[[ruleViewController stringTextfield] bind:@"enabled" toObject:rule withKeyPath:@"ModeRule" options:[NSDictionary dictionaryWithObject:NSNegateBooleanTransformerName forKey:NSValueTransformerNameBindingOption]];
		[[ruleViewController typePopup] bind:@"selectedTag" toObject:rule withKeyPath:@"TypeIdentifier" options:nil];
		[[ruleViewController typePopup] bind:@"enabled" toObject:rule withKeyPath:@"ModeRule" options:[NSDictionary dictionaryWithObject:NSNegateBooleanTransformerName forKey:NSValueTransformerNameBindingOption]];
		[[ruleViewController enabledCheckbox] bind:@"value" toObject:rule withKeyPath:@"Enabled" options:nil];
		[[ruleViewController warningImageView] bind:@"hidden" toObject:rule withKeyPath:@"Overridden" options:[NSDictionary dictionaryWithObject:NSNegateBooleanTransformerName forKey:NSValueTransformerNameBindingOption]];
		[[ruleViewController warningImageView] bind:@"hidden2" toObject:rule withKeyPath:@"Enabled" options:[NSDictionary dictionaryWithObject:NSNegateBooleanTransformerName forKey:NSValueTransformerNameBindingOption]];
		[[ruleViewController warningImageView] bind:@"toolTip" toObject:rule withKeyPath:@"OverriddenTooltip" options:nil];
		[[ruleViewController removeButton] bind:@"enabled" toObject:rule withKeyPath:@"ModeRule" options:[NSDictionary dictionaryWithObject:NSNegateBooleanTransformerName forKey:NSValueTransformerNameBindingOption]];
		
		if ([[rule objectForKey:@"ModeRule"] boolValue]) {
			[[ruleViewController view] setToolTip:NSLocalizedString(@"PrecedencePrefsModeRuleTooltip", @"Mode rules cannot be edited or removed. But you can disable them.")];
		}
		
		[ruleViews setObject:ruleViewController forKey:key];
	}
		
	[[ruleViewController view] setHidden:NO];
	
	//	NSLog(@"Drawing: %@", [[ruleViewController stringTextfield] stringValue]);		
	[(PrecedenceRuleCell *)cell setView:[ruleViewController view]];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
	if ([aNotification object] == o_rulesTableView) return;
	
	NSEnumerator *enumerator = [ruleViews objectEnumerator];
    id object;
    while ((object = [enumerator nextObject])) {
        [[object view] setHidden:YES]; 
    }
    [o_rulesTableView deselectAll:nil];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
	if (aTableView == o_rulesTableView) return NO;
	return YES;
}


@end
