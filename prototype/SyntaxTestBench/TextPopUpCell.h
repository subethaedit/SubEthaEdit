//
//  TextPopUpCell.h
//  XXP
//
//  Created by Dominik Wagner on Sat Mar 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TextPopUpCell : NSPopUpButtonCell {
    NSTextFieldCell *_textFieldCell;
}

- (float)desiredWidth;

@end

@interface NSObject (TextPopUpCellDelegation) 

- (void)textPopUpWillShowMenu:(NSPopUpButtonCell *)aCell;

@end

