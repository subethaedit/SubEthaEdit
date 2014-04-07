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

#define kUnresolvedSymbolAddress (void*)(~(uintptr_t)0)
#if defined(__LP64__)
static void (*SetItemMark)(MenuRef, MenuItemIndex, CharParameter) = kUnresolvedSymbolAddress;
#endif

- (void)setMark:(int)aMark {
#if defined(__LP64__)
	if (SetItemMark == kUnresolvedSymbolAddress) {
		void* handle = dlopen("/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/HIToolbox", (RTLD_LAZY | RTLD_LOCAL | RTLD_FIRST));
		if (handle != NULL) {
			SetItemMark = (__typeof__(SetItemMark))dlsym(handle, "SetItemMark");
		}
	}
#endif
	if (SetItemMark != NULL && _NSGetCarbonMenu != NULL) {
		SetItemMark(_NSGetCarbonMenu([self menu]), [[self menu] indexOfItem:self] + 1, aMark);
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
