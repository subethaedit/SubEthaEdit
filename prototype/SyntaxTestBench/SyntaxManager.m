//
//  SyntaxManager.m
//  Hydra
//
//  Created by Martin Pittenauer on Tue Mar 04 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import "SyntaxManager.h"
#import "SyntaxHighlighter.h"

static SyntaxManager *sharedInstance;

/*"You have to adjust this defnie to fit your Application Name"*/
#define kAppSupportSubEthaEditSynDefsPathComponent @"Application Support/SubEthaSyntaxHighlighter/Syntax Definitions/"

@implementation SyntaxManager

+ (SyntaxManager *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance=[[SyntaxManager alloc] init];
    }
    return sharedInstance;
}

- (id)init {
    self=[super init];
    if (self) {
        [self reloadSyntaxDefinitions];
    }
    return self;
}

- (void)reloadSyntaxDefinitions {
    NSString *file;
    NSDictionary *tempdir;
    NSString *syntaxFiles;
    NSString *path;
    NSEnumerator *enumerator = nil;
    NSDirectoryEnumerator *dirEnumerator = nil;
    
    [I_definitions release];
    I_definitions = [[NSMutableArray alloc] init];

    NSArray *userDomainPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    enumerator = [userDomainPaths objectEnumerator];
    while ((path = [enumerator nextObject])) {
        NSString *fullPath = [path stringByAppendingPathComponent:kAppSupportSubEthaEditSynDefsPathComponent];
        if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:nil]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:[fullPath stringByDeletingLastPathComponent] attributes:nil];
            [[NSFileManager defaultManager] createDirectoryAtPath:fullPath attributes:nil];
        }
    }
        
    NSMutableArray *allPaths = [NSMutableArray array];
    NSArray *allDomainsPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
    enumerator = [allDomainsPaths objectEnumerator];
    while ((path = [enumerator nextObject])) {
        [allPaths addObject:[path stringByAppendingPathComponent:kAppSupportSubEthaEditSynDefsPathComponent]];
    }
    
    [allPaths addObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Syntax Definitions/"]];
        
    enumerator = [allPaths objectEnumerator];
    while ((syntaxFiles = [enumerator nextObject])) {
        dirEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:syntaxFiles];
        while ((file = [dirEnumerator nextObject])) {
            if ([[file pathExtension] isEqualToString:@"plist"]) {
                    tempdir = [NSDictionary dictionaryWithContentsOfFile:[syntaxFiles stringByAppendingPathComponent:file]];
                    [I_definitions addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                [[tempdir objectForKey:kHeaderKey] objectForKey:kExtensionsKey], @"Extensions", 
                                [[tempdir objectForKey:kHeaderKey] objectForKey:kNameKey], @"Name",
                                [syntaxFiles stringByAppendingPathComponent:file], @"Filename",
                                NULL]];
            }
        }
    }

    
    int i;
    [I_availableSyntaxNames release];
    I_availableSyntaxNames = [NSMutableDictionary new];  
    for(i = [I_definitions count] - 1; i >= 0; i--) { // Pro file 
        [I_availableSyntaxNames setObject:[[I_definitions objectAtIndex:i] objectForKey:@"Filename"] 
                    forKey:[[I_definitions objectAtIndex:i] objectForKey:@"Name"]];
    }
}

- (NSDictionary *)availableSyntaxNames {
    return I_availableSyntaxNames;
}

/*"Returns the file path for the syntax definition for given extension anExtension"*/
- (NSString *)syntaxDefinitionForExtension:(NSString *)anExtension {
    unsigned int i,j;    
    for(i=0;i<[I_definitions count];i++) { // Pro file
        NSArray *extensions = [[[I_definitions objectAtIndex:i] objectForKey:@"Extensions"] componentsSeparatedByString:@","];
        for(j=0;j<[extensions count];j++) { // Pro extension
            if ([[extensions objectAtIndex:j] isEqualToString:anExtension]) {
                return [[I_definitions objectAtIndex:i] objectForKey:@"Filename"];
            }
        }
    }
    return nil;
}

/*"Returns the file path for the syntax definition with name aName"*/
- (NSString *)syntaxDefinitionForName:(NSString *)aName {
    unsigned int i;    
    for(i=0;i<[I_definitions count];i++) { // Pro file            
        if ([[[I_definitions objectAtIndex:i] objectForKey:@"Name"] isEqualToString:aName]) {
            return [[I_definitions objectAtIndex:i] objectForKey:@"Filename"];
        }
    }
    return nil;
}

@end
