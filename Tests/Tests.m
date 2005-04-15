#import <Cocoa/Cocoa.h>
#import <TCMFoundation/TCMBencodingUtilities.h>

NSData* TCMBencodingEncode(id object) {
    NSLog(@"Encoding object: %@", [object description]);
    
    NSData *result=TCM_BencodedObject(object);
    NSLog(@"Encoded version: %@",[[[NSString alloc] initWithBytes:[result bytes] length:[result length] encoding:NSMacOSRomanStringEncoding] autorelease]);
    return result;
}

id TCMBencodingDecode(NSData *data) {
    NSLog(@"Decoding data: %@",[[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSMacOSRomanStringEncoding] autorelease]);
    
    id result=TCM_BdecodedObjectWithData(data);
    NSLog(@"Decoded object: %@", [result description]);
    return result;
}

void TCMBencodingTest() {
    NSLog(@"Bencoding tests...");
    NSLog(@"==================");
    NSLog(@"");
    
    NSLog(@"round trip tests");
    NSLog(@"----------------");
    TCMBencodingDecode(TCMBencodingEncode([NSNumber numberWithInt:5]));
    TCMBencodingDecode(TCMBencodingEncode(@"Sample text"));
    TCMBencodingDecode(TCMBencodingEncode([NSNumber numberWithFloat:2.2]));
    TCMBencodingDecode(TCMBencodingEncode([NSArray arrayWithObjects:@"one",@"two",@"three",nil]));
    TCMBencodingDecode(TCMBencodingEncode([NSDictionary dictionaryWithObjectsAndKeys:@"content one",@"key one",@"content 2",@"key 2",nil]));
    TCMBencodingDecode(TCMBencodingEncode([NSArray arrayWithObjects:@"one",@"two",[NSDictionary dictionaryWithObjectsAndKeys:@"content one",@"key one",@"content 2",@"key 2",nil],nil]));
    TCMBencodingDecode(TCMBencodingEncode([NSDictionary dictionaryWithObjectsAndKeys:@"content one",@"key one",[NSArray arrayWithObjects:@"one",@"two",@"three",nil],@"key 2",nil]));
    NSLog(@"");
    
    NSLog(@"one way tests");
    NSLog(@"------------");
    TCMBencodingDecode([@":one3:twod7" dataUsingEncoding:NSMacOSRomanStringEncoding]);
    TCMBencodingDecode([@"d7:key one11:content one5:key 2l3:one3:two5:threeee" dataUsingEncoding:NSMacOSRomanStringEncoding]);
    TCMBencodingDecode([@"d7:key one11:content one:5:key 2l3:on" dataUsingEncoding:NSMacOSRomanStringEncoding]);
    TCMBencodingDecode([@"l3:one3:two3:shouldfail" dataUsingEncoding:NSMacOSRomanStringEncoding]);
    TCMBencodingDecode([@"d3:cnti133029683e4:name4:Cecy3:uID16...A.8..........$e" dataUsingEncoding:NSMacOSRomanStringEncoding]);
    TCMBencodingDecode([@"d6:rendez4:vous3:uid36:DDC5EF9E-A818-11D8-BF7B-00039398A6244:vers3:200e" dataUsingEncoding:NSMacOSRomanStringEncoding]);
    NSLog(@"");
}

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    TCMBencodingTest();
    // insert code here...
    NSLog(@"Tests finished");
    [pool release];
    return 0;
}
