//
//  NSMenuAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 27.03.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "NSMenuTCMAdditions.h"


@implementation  NSMenuItem (NSMenuItemTCMAdditions)
- (id)autoreleasedCopy {
    NSMenuItem *result=[[NSMenuItem alloc] initWithTitle:[self title] action:[self action] keyEquivalent:[self keyEquivalent]];
    [result setKeyEquivalentModifierMask:[self keyEquivalentModifierMask]];
    [result setTarget:[self target]];
    [result setTag:[self tag]];
    return [result autorelease];
}

- (NSComparisonResult)compareAlphabetically:(NSMenuItem *)aMenuItem {
    return [[self title] caseInsensitiveCompare:[aMenuItem title]];
}


// ~ is option
// ^ is control
// $ is shift
// @ would be commmand but is mandatory
- (void)setKeyEquivalentBySettingsString:(NSString *)aKeyEquivalentSettingsString {
    if ([aKeyEquivalentSettingsString length]<=0) return;
    [self setKeyEquivalent:[aKeyEquivalentSettingsString substringFromIndex:[aKeyEquivalentSettingsString length]-1]];
    unsigned int keyEquivalentModifierMask = NSCommandKeyMask;
    if ([aKeyEquivalentSettingsString rangeOfString:@"^"].location != NSNotFound) {
        keyEquivalentModifierMask |= NSControlKeyMask;
    }
    if ([aKeyEquivalentSettingsString rangeOfString:@"~"].location != NSNotFound) {
        keyEquivalentModifierMask |= NSAlternateKeyMask;
    }
    if ([aKeyEquivalentSettingsString rangeOfString:@"$"].location != NSNotFound) {
        keyEquivalentModifierMask |= NSShiftKeyMask;
    }
    [self setKeyEquivalentModifierMask:keyEquivalentModifierMask];
}


@end
