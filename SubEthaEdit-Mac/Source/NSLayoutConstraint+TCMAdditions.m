//  NSLayoutConstraint+TCMAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 09.04.14.

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "NSLayoutConstraint+TCMAdditions.h"

@implementation NSLayoutConstraint (TCMAdditions)
+ (instancetype)TCM_constraintWithItem:(id)aFirstItem secondItem:(id)aSecondItem equalAttribute:(NSLayoutAttribute)aLayoutAttribute {
	NSLayoutConstraint *result = [NSLayoutConstraint constraintWithItem:aFirstItem attribute:aLayoutAttribute relatedBy:NSLayoutRelationEqual toItem:aSecondItem attribute:aLayoutAttribute multiplier:1.0 constant:0.0];
	return result;
}
+ (instancetype)TCM_constraintWithItem:(id)aFirstItem secondItem:(id)aSecondItem equalAttribute:(NSLayoutAttribute)aLayoutAttribute secondAttribute:(NSLayoutAttribute)aSecondLayoutAttribute {
	NSLayoutConstraint *result = [NSLayoutConstraint constraintWithItem:aFirstItem attribute:aLayoutAttribute relatedBy:NSLayoutRelationEqual toItem:aSecondItem attribute:aSecondLayoutAttribute multiplier:1.0 constant:0.0];
	return result;
}
@end
