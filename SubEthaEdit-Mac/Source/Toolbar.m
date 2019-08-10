//  Toolbar.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 18.04.06.

#import "Toolbar.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

static int S_shouldNotNotifyOtherToolbars=0;

@implementation Toolbar

- (instancetype)initWithIdentifier:(NSString *)anIdentifier {
    if ((self=[super initWithIdentifier:anIdentifier])) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sizeModeDidChange:) name:@"ToolbarSizeModeDidChangeNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayModeDidChange:) name:@"ToolbarDisplayModeDidChangeNotification" object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)sizeModeDidChange:(NSNotification *)aNotification {
    if ([self sizeMode] != [[aNotification object] sizeMode]) {
        [self setSizeMode: [[aNotification object] sizeMode]];
    }
}

- (void)setSizeMode:(NSToolbarSizeMode)aSizeMode {
    BOOL shouldNotify=(aSizeMode!=[self sizeMode]);
    [super setSizeMode:aSizeMode];
    if (!S_shouldNotNotifyOtherToolbars && shouldNotify) {
        S_shouldNotNotifyOtherToolbars++;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ToolbarSizeModeDidChangeNotification" object:self];
        S_shouldNotNotifyOtherToolbars--;
    }
}

- (void)displayModeDidChange:(NSNotification *)aNotification {
    if ([self displayMode] !=[[aNotification object] displayMode]) {
        [self setDisplayMode:[[aNotification object] displayMode]];
    }
}

- (void)setDisplayMode:(NSToolbarDisplayMode)aDisplayMode {
    BOOL shouldNotify=(aDisplayMode!=[self displayMode]);
    [super setDisplayMode:aDisplayMode];
    if (!S_shouldNotNotifyOtherToolbars && shouldNotify) {
        S_shouldNotNotifyOtherToolbars++;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ToolbarDisplayModeDidChangeNotification" object:self];
        S_shouldNotNotifyOtherToolbars--;
    }
}


@end
