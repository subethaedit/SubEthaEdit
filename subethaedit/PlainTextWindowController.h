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
    IBOutlet NSDrawer *O_participantsDrawer;
    IBOutlet NSScrollView *O_participantsScrollView;
    IBOutlet ParticipantsView *O_participantsView;
}

@end
