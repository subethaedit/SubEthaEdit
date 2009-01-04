#import <Cocoa/Cocoa.h>
#import "ScalingScrollView.h"

@interface DocumentWindowController : NSWindowController {
    IBOutlet ScalingScrollView *scrollView;
    NSLayoutManager *layoutMgr;
    BOOL hasMultiplePages;
    BOOL rulerIsBeingDisplayed;
    BOOL isSettingSize;
}

// Convenience initializer. Loads the correct nib automatically.
- (id)init;

- (NSUInteger)numberOfPages;

- (void)doForegroundLayoutToCharacterIndex:(NSUInteger)loc;

- (NSView *)documentView;

- (void)breakUndoCoalescing;

@end
