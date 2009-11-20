#import <Cocoa/Cocoa.h>
#import "TCMMMUser.h"

@class ABPerson;

@interface TCMMMUser (AddressBook)

- (void)saveUserImageToApplicationSupport;
- (void)setUserImage:(NSImage*)inImage writeToSupportFolder:(BOOL)flag;
- (void)updateUserWithAddressCard:(ABPerson*)card;

@end
