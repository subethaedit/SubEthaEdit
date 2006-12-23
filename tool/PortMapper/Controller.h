/* Controller */

#import <Cocoa/Cocoa.h>

@interface Controller : NSObject
{
    IBOutlet NSTextField *portTextField;
    IBOutlet NSTextField *statusTextField;
}

- (IBAction) map:(id)sender;
- (IBAction) check:(id)sender;

@end
