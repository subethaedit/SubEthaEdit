#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	ABAddressBook *book=[ABAddressBook sharedAddressBook];
	ABPerson *me=[book me];
	ABMultiValue *value=[[[me valueForProperty:kABEmailProperty] copy] autorelease];
	NSLog(@"Primary identifier:%@",[value primaryIdentifier]);
	[value setValue:nil forKey:@"primaryIdentifier"];
	NSLog(@"Primary identifier:%@",[value primaryIdentifier]);
	[me setValue:value forProperty:kABEmailProperty];
	NSLog(@"Primary identifier after setting:%@",[[me valueForProperty:kABEmailProperty] primaryIdentifier]);
	NSLog(@"Did Save:%@",[book save]?@"YES":@"NO");
    // insert code here...
    NSLog(@"Hello, World!");
    [pool release];
    return 0;
}
