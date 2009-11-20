//
//  HUDStatisticGraphView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 18.09.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HUDStatisticGraphView : NSView {
    id statisticsEntryContainer;
    NSString *statisticsEntryKeyPath;
    BOOL relativeMode;
	NSTimeInterval timeInterval;
}

- (void)setRelativeMode:(BOOL)aFlag;
- (BOOL)relativeMode;

@end
