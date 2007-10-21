//
//  NSWindowScriptingAdditions.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 03.05.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSWindow (NSWindowScriptingAdditions)
- (id)scriptSelection;
- (void)setScriptSelection:(id)aSelection;
@end
