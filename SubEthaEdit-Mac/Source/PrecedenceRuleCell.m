//  PrecedenceRuleCell.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 22.09.07.

#import "PrecedenceRuleCell.h"
#import "DocumentModeManager.h"


@implementation PrecedenceRuleCell
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [super drawWithFrame:cellFrame inView:controlView];
    
    [_view setFrame:cellFrame];
    
    if (_view.superview != controlView) {
        [controlView addSubview:_view];
    }
}

- (void)setPlaceholderString:(NSString *)string {	
}
@end

@implementation RuleViewController {
    PrecedencePreferences *_preferenceController;
}

- (instancetype)init {
    if ((self = [super init])) {
        [[NSBundle mainBundle] loadNibNamed:@"PrecedenceRules" owner:self topLevelObjects:nil];
    }
    return self;
}

- (void)dealloc {
    [self.view removeFromSuperview];
}

- (void)setPreferenceController:(PrecedencePreferences*)controller {
    _preferenceController = controller;
}

- (IBAction)valuesChanged:(id)sender{
    [[DocumentModeManager sharedInstance] revalidatePrecedences];
}

- (IBAction)addRule:(id)sender {
    [_preferenceController addUserRule:self];
}

- (IBAction)removeRule:(id)sender {
    [_preferenceController removeUserRule:self];
}

@end
