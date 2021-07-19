//  NSMenuAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 27.03.06.

#import "NSMenuTCMAdditions.h"
#import <dlfcn.h>

@implementation  NSMenuItem (NSMenuItemTCMAdditions)
- (id)autoreleasedCopy {
    NSMenuItem *result=[[NSMenuItem alloc] initWithTitle:[self title] action:[self action] keyEquivalent:[self keyEquivalent]];
    [result setKeyEquivalentModifierMask:[self keyEquivalentModifierMask]];
    [result setTarget:[self target]];
    [result setTag:[self tag]];
    return result;
}

- (NSComparisonResult)compareAlphabetically:(NSMenuItem *)aMenuItem {
    return [[self title] caseInsensitiveCompare:[aMenuItem title]];
}

- (void)setMark:(BOOL)aMark {
	if (aMark) {
		// draw an image same size and dimentions like private image named "NSMenuItemBullet"
		NSImage* image = [NSImage imageWithSize:NSMakeSize(7.0, 7.0) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
			[[[NSColor blackColor] colorWithAlphaComponent:0.75] set];
			[[NSBezierPath bezierPathWithOvalInRect:dstRect] fill];
			return YES;
		}];

		if (image) {
			[self setMixedStateImage:image];
            [self setState:NSControlStateValueMixed];
		}
	} else {
		[self setMixedStateImage:[NSImage imageNamed:NSImageNameMenuMixedStateTemplate]];
        [self setState:NSControlStateValueOff];
	}
}


// ~ is option
// ^ is control
// $ is shift
// @ would be commmand but is mandatory
- (void)setKeyEquivalentBySettingsString:(NSString *)aKeyEquivalentSettingsString {
    if ([aKeyEquivalentSettingsString length]<=0) return;
    [self setKeyEquivalent:[aKeyEquivalentSettingsString substringFromIndex:[aKeyEquivalentSettingsString length]-1]];
    NSUInteger keyEquivalentModifierMask = NSEventModifierFlagCommand;
    if ([aKeyEquivalentSettingsString rangeOfString:@"^"].location != NSNotFound) {
        keyEquivalentModifierMask |= NSEventModifierFlagControl;
    }
    if ([aKeyEquivalentSettingsString rangeOfString:@"~"].location != NSNotFound) {
        keyEquivalentModifierMask |= NSEventModifierFlagOption;
    }
    if ([aKeyEquivalentSettingsString rangeOfString:@"$"].location != NSNotFound) {
        keyEquivalentModifierMask |= NSEventModifierFlagShift;
    }
    [self setKeyEquivalentModifierMask:keyEquivalentModifierMask];
}


@end
