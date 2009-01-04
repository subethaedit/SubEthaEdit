#import <Cocoa/Cocoa.h>


@interface PrintPanelAccessoryController : NSViewController <NSPrintPanelAccessorizing>

- (IBAction)changePageNumbering:(id)sender;

- (void)setPageNumbering:(BOOL)flag;
- (BOOL)pageNumbering;

@end
