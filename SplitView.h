//
//  SplitView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 13 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface SplitView : NSSplitView {
    float I_dividerThickness;
}

- (void)setDividerThickness:(float)aDividerThickness;

@end
