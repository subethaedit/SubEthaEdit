//  NSWindowScriptingAdditions.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 03.05.06.

#import <Cocoa/Cocoa.h>


@interface NSWindow (NSWindowScriptingAdditions)
- (id)scriptSelection;
- (void)setScriptSelection:(id)aSelection;
@end
