//
//  UserStatisticsController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 21.08.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "UserStatisticsController.h"
#import "HUDStatisticPersonCell.h"

#import <HMBlkAppKit/HMBlkAppKit.h>

@interface HMBlkPanel (MBlkPanelSEEAdditions)
+ (NSColor*)highlighedCellColor;
- (BOOL)canBecomeMainWindow;
@end

@implementation HMBlkPanel (MBlkPanelSEEAdditions)
+ (NSColor*)highlighedCellColor
{
    static NSColor* _highlightCellColor = nil;
    if (!_highlightCellColor) {
        _highlightCellColor = [[NSColor colorWithCalibratedWhite:0.15f alpha:0.8f] retain];
    }
    
    return _highlightCellColor;
}
- (BOOL)canBecomeMainWindow {
    return NO;
}
@end


@implementation UserStatisticsController

- (NSString *)windowNibName {
    return @"UserStatistics";
}

- (void)mainWindowDidChange:(NSNotification *)aNotification {
    [O_documentObjectController setContent:[[[NSApp mainWindow] windowController] document]];
}

- (void)windowDidLoad {
    [[O_userTableView tableColumnWithIdentifier:@"entries"] setDataCell:[[HUDStatisticPersonCell alloc] init]];
    [O_statEntryArrayController setSortDescriptors:
        [NSArray arrayWithObjects:
            [[[NSSortDescriptor alloc] initWithKey:@"dateOfLastActivity" ascending:NO] autorelease],
            nil
        ]
    ];
    [O_statEntryArrayController rearrangeObjects];
//    [O_statEntryArrayController addObserver:self forKeyPath:@"arrangedObjects.dateOfLastActivity" options:0 context:NULL];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rearrangeObjectsNotification:) name:@"UserStatisticsControllerRearrangeObjects" object:self];
//    [[self window] retain];
    [O_graphView bind:@"statisticsEntry" toObject:O_statEntryArrayController withKeyPath:@"selectedObjects" options:0];
    [O_percentageButton setState:NSOnState];
    BOOL relativeMode = [O_percentageButton state]==NSOnState;
    [O_graphView setRelativeMode:relativeMode];
    [[[[O_userTableView tableColumns] objectAtIndex:0] dataCell] setRelativeMode:relativeMode];
    [O_userTableView setNeedsDisplay:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowDidChange:) name:NSWindowDidBecomeMainNotification object:nil];
    [self mainWindowDidChange:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    NSLog(@"%s key:%@ object:%@ change:%@",__FUNCTION__,keyPath,object,change);
//    [O_userTableView setNeedsDisplay:YES];
//    [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:@"UserStatisticsControllerRearrangeObjects" object:self] postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender forModes:nil];
}

- (void)rearrangeObjectsNotification:(NSNotification *)aNotification {
    [O_statEntryArrayController rearrangeObjects];
}

- (IBAction)togglePercentage:(id)aSender {
    BOOL relativeMode = [aSender state]==NSOnState;
    [O_graphView setRelativeMode:relativeMode];
    [[[[O_userTableView tableColumns] objectAtIndex:0] dataCell] setRelativeMode:relativeMode];
    [O_userTableView setNeedsDisplay:YES];
}


@end
