#import <Cocoa/Cocoa.h>

@interface BorderlessWindow : NSWindow
{
    //This point is used in dragging to mark the initial click location
    NSPoint initialLocation;
    NSPoint initialResizing;
    BOOL shouldResize;
}
@end
