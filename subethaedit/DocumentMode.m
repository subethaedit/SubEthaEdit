//
//  DocumentMode.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "DocumentMode.h"
#import "SyntaxHighlighter.h"
#import "SyntaxDefinition.h"


@implementation DocumentMode

- (id)initWithBundle:(NSBundle *)aBundle {
    self = [super init];
    if (self) {
        I_bundle = [aBundle retain];
        SyntaxDefinition *synDef = [[[SyntaxDefinition alloc] initWithFile:[aBundle pathForResource:@"SyntaxDefinition" ofType:@"xml"]] autorelease];
        I_syntaxHighlighter = [[SyntaxHighlighter alloc] initWithSyntaxDefinition:synDef];
    }
    return self;
}

- (void) dealloc {
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


@end
