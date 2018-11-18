//  NSWorkspaceTCMAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 27.04.07.

#import "NSWorkspaceTCMAdditions.h"


static NSMutableDictionary *S_preresizedFileIcons=nil;

@implementation NSWorkspace (NSWorkspaceTCMAdditions) 

- (NSImage *)iconForFileType:(NSString *)aFileType size:(NSInteger)aSize {
    NSNumber *sizeNumber = [NSNumber numberWithInteger:aSize];
    
    if (!S_preresizedFileIcons) {
        S_preresizedFileIcons = [NSMutableDictionary new];
    }
    
    NSMutableDictionary *iconsByFileType = [S_preresizedFileIcons objectForKey:sizeNumber];
    if (!iconsByFileType) {
        iconsByFileType = [NSMutableDictionary dictionary];
        [S_preresizedFileIcons setObject:iconsByFileType forKey:sizeNumber];
    }
    
    NSImage *icon = [iconsByFileType objectForKey:aFileType];
    if (!icon) {
        icon = [[[[NSWorkspace sharedWorkspace] iconForFileType:aFileType] copy] autorelease];
        [icon setSize:NSMakeSize(aSize,aSize)];
        [iconsByFileType setObject:icon forKey:aFileType];
    }
    
    return icon;
}

@end
