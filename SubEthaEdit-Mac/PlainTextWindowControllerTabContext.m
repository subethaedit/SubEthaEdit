//
//  PlainTextWindowControllerTabContext.m
//  SubEthaEdit
//
//  Created by Martin Ott on 10/17/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "PlainTextWindowControllerTabContext.h"
#import "PlainTextWindowController.h"
#import "PlainTextLoadProgress.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif


@implementation PlainTextWindowControllerTabContext

- (id)init
{
    self = [super init];
    if (self) {
        _plainTextEditors = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_plainTextEditors makeObjectsPerformSelector:@selector(setWindowControllerTabContext:) withObject:nil];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, document: %@", [super description], self.document];
}

- (void)setIsAlertScheduled:(BOOL)flag
{
    if (flag) {
        [self setIcon:[NSImage imageNamed:@"SymbolWarn"]];
        [self setIconName:@"Alert"];
    } else {
        [self setIcon:nil];
        [self setIconName:@""];
    }
    _isAlertScheduled = flag;
}

@end
