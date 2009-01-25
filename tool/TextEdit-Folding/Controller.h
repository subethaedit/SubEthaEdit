#import <Cocoa/Cocoa.h>

@interface Controller : NSObject {
	int I_textStorageType;
}
+ (id)sharedInstance;
- (void)setTextStorageType:(int)inType;
- (int)textStorageType;
- (IBAction)changeTextStorageType:(id)inSender;
@end
