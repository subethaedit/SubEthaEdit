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
        I_documentModesByIdentifier =[NSMutableDictionary new];
		I_modeIdentifiersByExtension=[NSMutableDictionary new];
        [self TCM_findModes];
    }
    return self;
}

- (void)dealloc {
    [I_modeBundles release];
    [I_documentModesByIdentifier release];
	[I_modeIdentifiersByExtension release];
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
        NSEnumerator *dirEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];
        while ((file = [dirEnumerator nextObject])) {
			NSLog(@"%@",file);
            if ([[file pathExtension] isEqualToString:@"mode"]) {
                NSBundle *bundle = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:file]];
                if (bundle) {
					NSEnumerator *extensions = [[[bundle infoDictionary] objectForKey:@"TCMModeExtensions"] objectEnumerator];
					NSString *extension = nil;
					while ((extension = [extensions nextObject])) {
						[I_modeIdentifiersByExtension setObject:[bundle bundleIdentifier] forKey:extension];
					}
                    [I_modeBundles setObject:bundle forKey:[bundle bundleIdentifier]];
                }
            }
        }
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"DocumentModeManager, FoundModeBundles:%@",[I_modeBundles description]];
}

- (DocumentMode *)documentModeForIdentifier:(NSString *)anIdentifier {
	NSBundle *bundle=[I_modeBundles objectForKey:anIdentifier];
	if (bundle) {
        DocumentMode *mode=[I_documentModesByIdentifier objectForKey:anIdentifier];
        if (!mode) {
            mode = [[[DocumentMode alloc] initWithBundle:bundle] autorelease];
            if (mode)
                [I_documentModesByIdentifier setObject:mode forKey:anIdentifier];
        }
        return mode;
	} else {
        return nil;
    }
}

- (DocumentMode *)baseMode {
    return [self documentModeForIdentifier:@"de.codingmonkeys.SubEthaEdit.mode.Base"];
}

- (DocumentMode *)documentModeForExtension:(NSString *)anExtension {
    NSString *identifier=[I_modeIdentifiersByExtension objectForKey:anExtension];
    if (identifier) {
        return [self documentModeForIdentifier:identifier];
	} else {
        return [self baseMode];
	}
}


/*"Returns an NSDictionary with Key=Identifier, Value=ModeName"*/
- (NSDictionary *)availableModes {
    NSMutableDictionary *result=[NSMutableDictionary dictionary];
    NSEnumerator *modeIdentifiers=[I_modeBundles keyEnumerator];
    NSString *identifier = nil;
    while ((identifier=[modeIdentifiers nextObject])) {
        [result setObject:[[[I_modeBundles objectForKey:identifier] localizedInfoDictionary] objectForKey:@"CFBundleName"] 
                   forKey:identifier];
    }
    return result;
}


@end
