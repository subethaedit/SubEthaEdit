//
//  URLImageView.h
//  SubEthaEdit
//
//  Created by Martin Ott on Wed May 05 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface URLImageView : NSImageView {
    NSTrackingRectTag I_trackingRectTag;
    id I_delegate;
}

- (void)setDelegate:(id)aDelegate;
- (id)delegate;

@end

@interface NSObject (URLImageViewDelegateAdditions)
- (NSURL*)URLForURLImageView:(URLImageView *)anImageView;
@end

