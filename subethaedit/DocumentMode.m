//
//  DocumentMode.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "DocumentMode.h"
#import "DocumentModeManager.h"
#import "SyntaxHighlighter.h"
#import "SyntaxDefinition.h"


@implementation DocumentMode

- (id)initWithBundle:(NSBundle *)aBundle {
    self = [super init];
    if (self) {
        I_bundle = [aBundle retain];
        SyntaxDefinition *synDef = [[[SyntaxDefinition alloc] initWithFile:[aBundle pathForResource:@"SyntaxDefinition" ofType:@"xml"]] autorelease];
        I_syntaxHighlighter = [[SyntaxHighlighter alloc] initWithSyntaxDefinition:synDef];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
        NSMutableDictionary *dictionary=[[[[NSUserDefaults standardUserDefaults] objectForKey:[[self bundle] bundleIdentifier]] mutableCopy] autorelease];
        if (dictionary) {
            [self setDefaults:dictionary];
        } else {
            I_defaults = [NSMutableDictionary new];
            [I_defaults setObject:[NSNumber numberWithInt:3] forKey:@"TabWidth"];
            NSFont *font=[NSFont userFixedPitchFontOfSize:0.0];
            NSMutableDictionary *dict=[NSMutableDictionary dictionary];
            [dict setObject:[font fontName] 
                     forKey:NSFontNameAttribute];
            [dict setObject:[NSNumber numberWithFloat:[font pointSize]] 
                     forKey:NSFontSizeAttribute];
            [I_defaults setObject:dict forKey:@"FontAttributes"];
        }
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [I_defaults release];
    [I_syntaxHighlighter release];
    [I_bundle release];
    [super dealloc];
}

- (NSBundle *)bundle {
    return I_bundle;
}

- (SyntaxHighlighter *)syntaxHighlighter {
    return I_syntaxHighlighter;
}

- (NSMutableDictionary *)defaults {
    return I_defaults;
}
- (void)setDefaults:(NSMutableDictionary *)defaults {
    [I_defaults autorelease];
    I_defaults=[defaults retain];
}

- (BOOL)isBaseMode {
    return [self isEqualTo:[[DocumentModeManager sharedInstance] baseMode]];
}

#pragma mark -
#pragma mark ### Notification Handling ###

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[NSUserDefaults standardUserDefaults] setObject:[self defaults] forKey:[[self bundle] bundleIdentifier]];
}

@end
