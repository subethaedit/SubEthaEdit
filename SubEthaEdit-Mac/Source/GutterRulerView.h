//  GutterRulerView.h
//  SubEthaHighlighter
//
//  Created by Dominik Wagner on Mon May 05 2003.

#import <AppKit/AppKit.h>
#import "FoldableTextStorage.h"


@interface GutterRulerView : NSRulerView
@property (nonatomic) BOOL suspendDrawing;
@end
