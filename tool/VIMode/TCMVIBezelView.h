//
//  TCMBezelView.h
//  VIMode
//
//  Created by Martin Pittenauer on 25.04.05.
//  Copyright 2005 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TCMVIBezelView : NSView {
    NSString *I_description;
    NSString *I_command;
}
- (void) showCommand:(NSString *)command withDescription:(NSString *)description;
@end

@interface NSBezierPath(BezelViewBezierPathAdditions)
+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect radius:(float)radius;
@end
