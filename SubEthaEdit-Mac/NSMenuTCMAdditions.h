//
//  NSMenuAdditions.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 27.03.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h> 

extern MenuRef _NSGetCarbonMenu(NSMenu* aMenu);

@interface NSMenu (NSMenuTCMAdditions)
- (void)removeAllItems;
@end

@interface NSMenuItem (NSMenuItemTCMAdditions)
- (void)setMark:(BOOL)aMark;
- (id)autoreleasedCopy;
- (NSComparisonResult)compareAlphabetically:(NSMenuItem *)aNotherMenuItem;
- (void)setKeyEquivalentBySettingsString:(NSString *)aKeyEquivalentSettingsString;
@end
