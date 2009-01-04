#import <Cocoa/Cocoa.h>


@interface DocumentPropertiesPanelController : NSWindowController {
    IBOutlet id documentObjectController;
    id inspectedDocument;
}

- (void)toggleWindow:(id)sender;

@end
