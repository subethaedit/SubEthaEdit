//
//  DocumentModeManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "DocumentModeManager.h"

#define MODEPATHCOMPONENT @"Application Support/SubEthaEdit/Modes/"

static DocumentModeManager *sharedInstance;

@interface DocumentModeManager (DocumentModeManagerPrivateAdditions)
- (void)TCM_findModes;
@end

@implementation DocumentModeManager

+ (DocumentModeManager *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [self new];
    }
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        I_modeBundles=[NSMutableDictionary new];
        I_modes      =[NSMutableDictionary new];
        [self TCM_findModes];
    }
    return self;
}

- (void)dealloc {
    [I_modeBundles release];
    [I_modes release];
    [super dealloc];
}

- (void)TCM_findModes {
    NSString *file;
    NSString *path;
        
    NSMutableArray *allPaths = [NSMutableArray array];
    NSArray *allDomainsPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
    NSEnumerator *enumerator = [allDomainsPaths objectEnumerator];
    while ((path = [enumerator nextObject])) {
        [allPaths addObject:[path stringByAppendingPathComponent:MODEPATHCOMPONENT]];
    }
    
    [allPaths addObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Modes/"]];
    
    enumerator = [allPaths reverseObjectEnumerator];
    while ((path = [enumerator nextObject])) {
        NSDirectoryEnumerator *dirEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
        while ((file = [dirEnumerator nextObject])) {
            if ([[file pathExtension] isEqualToString:@"mode"]) {
                NSBundle *bundle = [NSBundle bundleWithPath:file];
                if (bundle) {
                    [I_modeBundles setObject:bundle forKey:[[bundle bundlePath] lastPathComponent]];
                }
            }
        }
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"DocumentModeManager, FoundModeBundles:%@",[I_modeBundles description]];
}

@end
