//
//  PlainTextWindowController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Mar 05 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>


@class ParticipantsView;


@interface PlainTextWindowController : NSWindowController {
    IBOutlet NSTextView *O_textView;

    // praticipants
    IBOutlet NSDrawer         *O_participantsDrawer;
    IBOutlet NSScrollView     *O_participantsScrollView;
    IBOutlet NSSplitView      *O_participantsSplitView;
    IBOutlet NSView           *O_newUserView;
    IBOutlet ParticipantsView *O_participantsView;
    IBOutlet NSPopUpButton    *O_actionPullDown;    
}

@end
