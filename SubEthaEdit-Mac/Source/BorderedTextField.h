//  BorderedTextField.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 07.12.05.

#import <Cocoa/Cocoa.h>


@interface BorderedTextField : NSTextField 

@property (nonatomic, strong) NSColor *borderColor;
@property (nonatomic) BOOL hasRightBorder;
@property (nonatomic) BOOL hasLeftBorder;

@end
