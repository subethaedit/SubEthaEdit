//
//  ParticipantsView.h
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "TCMListView.h"

enum {
    ParticipantsItemStatusImageTag,
    ParticipantsItemNameTag,
    ParticipantsChildImageTag,
    ParticipantsChildNameTag,
    ParticipantsChildImageNextToNameTag,
    ParticipantsChildStatusImageTag,
    ParticipantsChildStatusTag
};

@class PlainTextDocument;

@interface ParticipantsView : TCMListView
{
    int I_dragToItem;
    NSWindowController *I_windowController;
}

- (void)setWindowController:(NSWindowController *)aWindowController;
- (NSWindowController *)windowController;
- (PlainTextDocument *)document;

@end

