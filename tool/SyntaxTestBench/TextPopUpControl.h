//
//  TextPopUpControl.h
//  XXP
//
//  Created by Dominik Wagner on Sun Mar 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "TextPopUpCell.h"

@interface TextPopUpControl : NSPopUpButton {
    id _delegate;
}

- (id)delegate;
- (void)setDelegate:(id)aDelegate;
@end
