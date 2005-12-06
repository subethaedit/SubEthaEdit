//
//  CandyBarView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 06.12.05.
//  Copyright 2005 TheCodingMonkeys. All rights reserved.
//

#import "CandyBarView.h"

static NSColor *sBackgroundColor=nil;


@implementation CandyBarView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
      if (!sBackgroundColor) 
        sBackgroundColor=[[NSColor colorWithPatternImage:[NSImage imageNamed:@"CandyBar"]] retain];
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    NSImage *fillImage=[NSImage imageNamed:@"CandyBar"];
    [fillImage setFlipped:YES];
    [fillImage drawInRect:[self bounds] fromRect:NSMakeRect(0,0,[fillImage size].width,[fillImage size].height) operation:NSCompositeCopy fraction:1.0];
}

- (BOOL)isOpaque {
  return YES;
}
@end
