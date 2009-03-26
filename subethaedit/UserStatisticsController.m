//
//  UserStatisticsController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 21.08.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "UserStatisticsController.h"
#import "HUDStatisticPersonCell.h"
#import "TCMMMLogStatisticsEntry.h"
#import "TCMMMUser.h"

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
- (BOOL)canBecomeKeyWindow {
    return YES;
}


@end

static NSString *s_scheduleContext = @"ScheduleContext";
static NSString *s_updateContext   = @"UpdateContext";

@implementation UserStatisticsController

- (void)updateWordCount {
    id document = [O_documentObjectController content];
    if (document) {
        [O_wordCountTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%@ lines, %@ words, %@ characters",@"word count string in statistics controller"), 
            [NSString stringByAddingThousandSeparatorsToNumber:[document valueForKeyPath:@"textStorage.numberOfLines"]],
            [NSString stringByAddingThousandSeparatorsToNumber:[document valueForKeyPath:@"textStorage.numberOfWords"]],
            [NSString stringByAddingThousandSeparatorsToNumber:[document valueForKeyPath:@"textStorage.numberOfCharacters"]]]];
    } else {
        [O_wordCountTextField setStringValue:@""];
    }
    I_wordCountUpdateScheduled = NO;
}

- (void)showWindow:(id)aSender {
    [self window];
    [self updateWordCount];
    [O_documentObjectController setContent:[[[NSApp mainWindow] windowController] document]];
    [super showWindow:aSender];
}

- (NSString *)windowNibName {
    return @"UserStatistics";
}

- (void)windowWillClose:(NSNotification *)aNotification {
    NSWindow *notificationWindow = [aNotification object];
    if ([notificationWindow isMainWindow]) {
        [O_documentObjectController setContent:nil];
    } if (notificationWindow == [self window]) {
        [O_documentObjectController setContent:nil];
    }
}


- (void)mainWindowDidChange:(NSNotification *)aNotification {
    NSWindow *window = [aNotification object];
    if ([[self window] isVisible]) {
        if (!window || ![window isKindOfClass:[NSWindow class]]) {
            window = [NSApp mainWindow];
        }
        [O_documentObjectController setContent:[[window windowController] document]];
    }
}

- (void)windowDidLoad {
    I_wordCountUpdateScheduled = NO;
    
    [[O_userTableView tableColumnWithIdentifier:@"entries"] setDataCell:[[[HUDStatisticPersonCell alloc] init] autorelease]];
    [O_statEntryArrayController setSortDescriptors:
        [NSArray arrayWithObjects:
            [[[NSSortDescriptor alloc] initWithKey:@"dateOfLastActivity" ascending:NO] autorelease],
            nil
        ]
    ];
    [O_statEntryArrayController rearrangeObjects];
    [O_documentObjectController addObserver:self forKeyPath:@"selection" options:0 context:s_updateContext];
    [O_documentObjectController addObserver:self forKeyPath:@"selection.textStorage.numberOfLines" options:0 context:s_scheduleContext];
    [O_graphView bind:@"statisticsEntry" toObject:O_statEntryArrayController withKeyPath:@"selectedObjects" options:0];
    [O_percentageButton setState:NSOnState];
    BOOL relativeMode = [O_percentageButton state]==NSOnState;
    [O_graphView setRelativeMode:relativeMode];
    [[[[O_userTableView tableColumns] objectAtIndex:0] dataCell] setRelativeMode:relativeMode];
    [O_userTableView setNeedsDisplay:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowDidChange:) name:NSWindowDidBecomeMainNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowDidChange:) name:@"PlainTextWindowControllerDocumentDidChangeNotification" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:nil];
        
    [(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:NO];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == s_updateContext) {
        [self updateWordCount];
    } else if (!I_wordCountUpdateScheduled) {
        [self performSelector:@selector(updateWordCount) withObject:self afterDelay:0.5];
        I_wordCountUpdateScheduled = YES;
    }
}

- (IBAction)togglePercentage:(id)aSender {
    BOOL relativeMode = [aSender state]==NSOnState;
    [O_graphView setRelativeMode:relativeMode];
    [[[[O_userTableView tableColumns] objectAtIndex:0] dataCell] setRelativeMode:relativeMode];
    [O_userTableView setNeedsDisplay:YES];
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)aRow mouseLocation:(NSPoint)mouseLocation {
    NSArray *array = [O_statEntryArrayController arrangedObjects];
    if ([array count] > aRow) {
        TCMMMUser *user = [(TCMMMLogStatisticsEntry *)[array objectAtIndex:aRow] user];
        if (user) {
            return [NSString stringWithFormat:@"AIM:%@\nEmail:%@",[[user properties] objectForKey:@"AIM"],[[user properties] objectForKey:@"Email"]];
        }
    }
    return nil;
}


@end
