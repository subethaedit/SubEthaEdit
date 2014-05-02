//
//  NSMenuAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 27.03.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "NSMenuTCMAdditions.h"
#import <dlfcn.h>

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

- (void)setMark:(BOOL)aMark {
	if (aMark)
	{
//		CGFloat fontSize = 20.0;
//		NSImage* image = [NSImage imageWithSize:NSMakeSize(fontSize, fontSize) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
//			NSString *bulletString = @"•";
//
//			NSDictionary *attributes = @{NSFontAttributeName: [NSFont menuFontOfSize:fontSize]};
//
//			[bulletString drawInRect:dstRect withAttributes:attributes];
//			return YES;
//		}];

		NSImage* image = [NSImage imageNamed:@"NSMenuItemBullet"];
		if (image) {
			[self setMixedStateImage:image];
			[self setState:NSMixedState];
		}
	} else {
		[self setMixedStateImage:[NSImage imageNamed:NSImageNameMenuMixedStateTemplate]];
		[self setState:NSOffState];
	}
}


// ~ is option
// ^ is control
// $ is shift
// @ would be commmand but is mandatory
- (void)setKeyEquivalentBySettingsString:(NSString *)aKeyEquivalentSettingsString {
    if ([aKeyEquivalentSettingsString length]<=0) return;
    [self setKeyEquivalent:[aKeyEquivalentSettingsString substringFromIndex:[aKeyEquivalentSettingsString length]-1]];
    NSUInteger keyEquivalentModifierMask = NSCommandKeyMask;
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
