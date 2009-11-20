//
//  PSMTabBarControlInspector.m
//  PSMTabBarControl
//
//  Created by John Pannell on 12/21/05.
//  Copyright Positive Spin Media 2005 . All rights reserved.
//

#import "PSMTabBarControlInspector.h"
#import "PSMTabBarControl.h"

#define kPSMStyleTag 0
#define kPSMCanCloseOnlyTabTag 1
#define kPSMHideForSingleTabTag 2
#define kPSMShowAddTabTag 3
#define kPSMMinWidthTag 4
#define kPSMMaxWidthTag 5
#define kPSMOptimumWidthTag 6
#define kPSMSizeToFitTag 7
#define kPSMAutomaticallyAnimates 8
#define kPSMDisableTabClose 9
#define kPSMUseOverflowMenu 10
#define kPSMSelectTabsOnMouseDown 11
#define kPSMAllowsBackgroundTabClosing 12

@implementation PSMTabBarControlInspector

- (id)init
{
    self = [super init];
    [NSBundle loadNibNamed:@"PSMTabBarControlInspector" owner:self];
    return self;
}

- (void)ok:(id)sender
{
    if ([sender tag] == kPSMStyleTag) {
        [[self object] setStyleNamed:[sender titleOfSelectedItem]];
    } else if ([sender tag] == kPSMCanCloseOnlyTabTag) {
        [[self object] setCanCloseOnlyTab:[sender state]];
    } else if ([sender tag] == kPSMHideForSingleTabTag) {
        [[self object] setHideForSingleTab:[sender state]];
    } else if ([sender tag] == kPSMShowAddTabTag) {
        [[self object] setShowAddTabButton:[sender state]];
    } else if ([sender tag] == kPSMMinWidthTag) {
        if ([[self object] cellOptimumWidth] < [sender intValue]) {
            [[self object] setCellMinWidth:[[self object] cellOptimumWidth]];
            [sender setIntValue:[[self object] cellOptimumWidth]];
        } else {
            [[self object] setCellMinWidth:[sender intValue]];
        }
    } else if ([sender tag] == kPSMMaxWidthTag) {
        if ([[self object] cellOptimumWidth] > [sender intValue]) {
            [[self object] setCellMaxWidth:[[self object] cellOptimumWidth]];
            [sender setIntValue:[[self object] cellOptimumWidth]];
        } else {
            [[self object] setCellMaxWidth:[sender intValue]];
        }
    } else if ([sender tag] == kPSMOptimumWidthTag) {
        if ([[self object] cellMaxWidth] < [sender intValue]) {
            [[self object] setCellOptimumWidth:[[self object] cellMaxWidth]];
            [sender setIntValue:[[self object] cellMaxWidth]];
        } else if ([[self object] cellMinWidth] > [sender intValue]) {
            [[self object] setCellOptimumWidth:[[self object] cellMinWidth]];
            [sender setIntValue:[[self object] cellMinWidth]];
        } else {
            [[self object] setCellOptimumWidth:[sender intValue]];
        }
    } else if ([sender tag] == kPSMSizeToFitTag) {
        [[self object] setSizeCellsToFit:[sender state]];
    } else if ([sender tag] == kPSMDisableTabClose) {
        [[self object] setDisableTabClose:[sender state]];
    } else if ([sender tag] == kPSMUseOverflowMenu) {
		[[self object] setUseOverflowMenu:[sender state]];
	} else if ([sender tag] == kPSMAutomaticallyAnimates) {
		[[self object] setAutomaticallyAnimates:[sender state]];
	} else if ([sender tag] == kPSMSelectTabsOnMouseDown) {
		[[self object] setSelectsTabsOnMouseDown:[sender state]];
	} else if ([sender tag] == kPSMAllowsBackgroundTabClosing) {
		[[self object] setAllowsBackgroundTabClosing:[sender state]];
	}
    
    [super ok:sender];
}

- (void)revert:(id)sender
{
    [_stylePopUp selectItemWithTitle:[[self object] styleName]];
    [_canCloseOnlyTab setState:[[self object] canCloseOnlyTab]];
	[_disableTabClose setState:[[self object] disableTabClose]];
    [_hideForSingleTab setState:[[self object] hideForSingleTab]];
    [_showAddTab setState:[[self object] showAddTabButton]];
    [_cellMinWidth setIntValue:[[self object] cellMinWidth]];
    [_cellMaxWidth setIntValue:[[self object] cellMaxWidth]];
    [_cellOptimumWidth setIntValue:[[self object] cellOptimumWidth]];
    [_sizeToFit setState:[[self object] sizeCellsToFit]];
	[_useOverflowMenu setState:[[self object] useOverflowMenu]];
    [_automaticallyAnimates setState:[[self object] automaticallyAnimates]];
	[_selectsTabsOnMouseDown setState:[[self object] selectsTabsOnMouseDown]];
	[_allowsBackgroundTabClosing setState:[[self object] allowsBackgroundTabClosing]];
	
    [super revert:sender];
}

@end
