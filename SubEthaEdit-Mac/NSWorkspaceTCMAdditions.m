//
//  NSWorkspaceTCMAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 27.04.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "NSWorkspaceTCMAdditions.h"


static NSMutableDictionary *S_preresizedFileIcons=nil;

@implementation NSWorkspace (NSWorkspaceTCMAdditions) 
- (NSImage *) iconForFileType:(NSString *)anExtension size:(int)aSize {
    NSNumber *sizeNumber = [NSNumber numberWithInt:aSize];
    
    if (!S_preresizedFileIcons) {
        S_preresizedFileIcons = [NSMutableDictionary new];
    }
    
    NSMutableDictionary *iconsByExtension = [S_preresizedFileIcons objectForKey:sizeNumber];
    if (!iconsByExtension) {
        iconsByExtension = [NSMutableDictionary dictionary];
        [S_preresizedFileIcons setObject:iconsByExtension forKey:sizeNumber];
    }
    
    NSImage *icon = [iconsByExtension objectForKey:anExtension];
    if (!icon) {
        icon = [[[NSWorkspace sharedWorkspace] iconForFileType:anExtension] copy];
        [icon setSize:NSMakeSize(aSize,aSize)];
        [iconsByExtension setObject:icon forKey:anExtension];
    }
    
    return icon;
}
@end
