//  RadarScroller.h
//  XXP
//
//  Created by Dominik Wagner on Mon Feb 17 2003.

#import <Foundation/Foundation.h>


@interface RadarScroller : NSScroller {
    NSMutableDictionary *I_marks;
    float I_maxHeight;
}

- (void)setMaxHeight:(int)maxHeight;

- (void)setMarkFor:(NSString *)aIdentifier withColor:(NSColor *)aColor 
       forMinLocation:(float)aMinLocation andMaxLocation:(float)aMaxLocation;
- (void)removeMarkFor:(NSString *)aIdentifier;

@end
