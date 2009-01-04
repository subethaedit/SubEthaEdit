//
//  TextView.h
//  TextEdit
//
//  Created by Dominik Wagner on 04.01.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FoldableTextStorage.h"


@interface TextView : NSTextView {

}

- (void)collapseSelection:(id)inSender;

@end
