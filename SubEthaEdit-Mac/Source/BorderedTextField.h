//  BorderedTextField.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 07.12.05.

#import <Cocoa/Cocoa.h>


@interface BorderedTextField : NSTextField {
    struct {
        BOOL hasLeftBorder;
        BOOL hasRightBorder;
    } I_flags;
    NSColor *I_borderColor;
}

- (void)setHasRightBorder:(BOOL)aFlag;
- (void)setHasLeftBorder:(BOOL)aFlag;
- (void)setBorderColor:(NSColor *)aColor;

@end
