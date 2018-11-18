//  NSLayoutConstraint+TCMAdditions.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 09.04.14.

#import <Cocoa/Cocoa.h>

@interface NSLayoutConstraint (TCMAdditions)
+ (instancetype)TCM_constraintWithItem:(id)aFirstItem secondItem:(id)aSecondItem equalAttribute:(NSLayoutAttribute)aLayoutAttribute;
+ (instancetype)TCM_constraintWithItem:(id)aFirstItem secondItem:(id)aSecondItem equalAttribute:(NSLayoutAttribute)aLayoutAttribute secondAttribute:(NSLayoutAttribute)aSecondLayoutAttribute;
@end
