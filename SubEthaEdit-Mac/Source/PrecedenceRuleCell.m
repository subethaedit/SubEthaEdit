//  PrecedenceRuleCell.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 22.09.07.

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
		// there are strong outlets to every top level nib object, so no additional array is needed to hold them.
		[[NSBundle mainBundle] loadNibNamed:@"PrecedenceRules" owner:self topLevelObjects:nil];
		preferenceController = nil;
    }
    return self;
}

- (void) dealloc
{
	[self.view removeFromSuperview];
	self.view = nil;

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

@end
