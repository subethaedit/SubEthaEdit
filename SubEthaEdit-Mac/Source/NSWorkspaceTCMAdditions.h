//  NSWorkspaceTCMAdditions.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 27.04.07.

#import <Cocoa/Cocoa.h>


@interface NSWorkspace (NSWorkspaceTCMAdditions) 
- (NSImage *)iconForFileType:(NSString *)anExtension size:(NSInteger)aSize;
@end
