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
    ParticipantsChildStatusTag
};


@interface ParticipantsView : TCMListView
{
}
@end

