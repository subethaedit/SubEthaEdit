//
//  URLImageView.h
//  SubEthaEdit
//
//  Created by Martin Ott on Wed May 05 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface URLImageView : NSImageView {
    IBOutlet id O_windowController;
    NSTrackingRectTag I_trackingRectTag;
}

@end
