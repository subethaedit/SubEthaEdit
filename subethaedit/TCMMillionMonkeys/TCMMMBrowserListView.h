//
//  TCMMMBrowserListView.h
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "TCMListView.h"

enum {
    TCMMMBrowserItemImageTag,
    TCMMMBrowserItemNameTag,
    TCMMMBrowserItemImageNextToNameTag,
    TCMMMBrowserItemStatusTag,
    TCMMMBrowserItemActionImageTag = TCMListViewActionButtonImageTag,
    TCMMMBrowserChildIconImageTag,
    TCMMMBrowserChildNameTag,
    TCMMMBrowserChildStatusImageTag,
    TCMMMBrowserChildActionImageTag
};

@interface TCMMMBrowserListView : TCMListView
{
}
@end
