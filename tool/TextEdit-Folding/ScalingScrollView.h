#import <Cocoa/Cocoa.h>

@class NSPopUpButton;

@interface ScalingScrollView : NSScrollView {
    NSPopUpButton *_scalePopUpButton;
    CGFloat scaleFactor;
}

- (void)scalePopUpAction:(id)sender;
- (void)setScaleFactor:(CGFloat)factor adjustPopup:(BOOL)flag;
- (CGFloat)scaleFactor;

@end
