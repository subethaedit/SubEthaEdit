#import <Cocoa/Cocoa.h>


@interface LinePanelController : NSWindowController {
    IBOutlet NSTextField *lineField;
}

- (IBAction)lineFieldChanged:(id)sender;
- (IBAction)selectClicked:(id)sender;

@end
