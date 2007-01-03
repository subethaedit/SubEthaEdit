//
//  DWRoundedTransparentView.h
//  Glasnost
//
//  Created by Dominik Wagner on 07.05.05.
//  Copyright 2005 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSBezierPath(BezierPathDWAdditions)
+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect radius:(float)radius;
+ (NSBezierPath *)bezierPathWithTopCapOfRoundedRect:(NSRect)rect radius:(float)radius;
@end


@interface DWRoundedTransparentView : NSView {
    NSString *I_titleString;
}

- (NSString *)title;
- (void)setTitle:(NSString *)aTitle;

@end
