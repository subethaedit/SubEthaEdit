//
//  HUDStatisticPersonCell.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 19.09.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HUDStatisticPersonCell : NSCell {
    BOOL relativeMode;
}

- (void)setRelativeMode:(BOOL)aFlag;
- (BOOL)relativeMode;

@end
