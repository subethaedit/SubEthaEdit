//
//  OverlayView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 21.10.04.
//  Copyright 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface OverlayView : NSView {
    BOOL I_isDragTarget;
    id I_delegate;
}

- (void)setIsDragTarget:(BOOL)aFlag;
- (void)setDelegate:(id)aSender;

@end
