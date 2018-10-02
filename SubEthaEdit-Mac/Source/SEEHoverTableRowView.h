#import <Cocoa/Cocoa.h>

@interface SEEHoverTableRowView : NSTableRowView {
}

@property (nonatomic) BOOL clickHighlight;
@property (nonatomic, readonly) BOOL mouseInside;
@property (nonatomic) NSInteger TCM_rowIndex;
- (void)TCM_updateMouseInside;

@end

