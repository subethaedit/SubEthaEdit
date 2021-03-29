//  DocumentModeMenu.m
//  SubEthaEdit
//
//  Created by dom on 29.03.2021.

#import "DocumentModeMenu.h"
#import "DocumentModeManager.h"

@implementation DocumentModeMenu
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)documentModeListChanged:(NSNotification *)notification {
    [[DocumentModeManager sharedInstance] setupMenu:self action:I_action alternateDisplay:I_alternateDisplay];
}

- (void)configureWithAction:(SEL)aSelector alternateDisplay:(BOOL)aFlag {
    I_action = aSelector;
    I_alternateDisplay = aFlag;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentModeListChanged:) name:@"DocumentModeListChanged" object:nil];
    [[DocumentModeManager sharedInstance] setupMenu:self action:I_action alternateDisplay:aFlag];
}
@end

