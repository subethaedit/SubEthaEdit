//
//  ButtonScrollView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Apr 15 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ButtonScrollView : NSScrollView {
    NSButton *I_button;
}

- (NSButton *)button;

@end
