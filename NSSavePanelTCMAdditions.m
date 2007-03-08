//
//  NSSavePanelTCMAdditions.m
//  SubEthaEdit
//
//  Created by Martin Ott on 2/20/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "NSSavePanelTCMAdditions.h"


@implementation NSSavePanel (NSSavePanelTCMAdditions)

- (BOOL)canShowHiddenFiles {
    if ([self respondsToSelector:@selector(_navView)]) {
        id navView = [self _navView];
        if ([navView respondsToSelector:@selector(setShowsHiddenFiles:)]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)setInternalShowsHiddenFiles:(BOOL)flag {
    if ([self canShowHiddenFiles]) {
        [[self _navView] setShowsHiddenFiles:flag];
    }
}

@end
