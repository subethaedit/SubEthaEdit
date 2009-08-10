//
//  GutterRulerView.h
//  SubEthaHighlighter
//
//  Created by Dominik Wagner on Mon May 05 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "FoldableTextStorage.h"

@interface GutterRulerView : NSRulerView {
	NSPoint I_lastMouseDownPoint;
}

@end
