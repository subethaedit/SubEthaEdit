//
//  DataTests.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 18.09.06.
//  Copyright (c) 2006 TheCodingMonkeys. All rights reserved.
//

#import "DataTests.h"
#import "TCMBencodingUtilities.h"

@implementation DataTests

- (void)setUp {}

- (void)roundtripBencode:(id)anObject {
    STAssertEqualObjects(
        TCM_BdecodedObjectWithData(TCM_BencodedObject(anObject)),
        anObject,
        @"round-trip bencoding of %@", anObject);
}

- (void)bdecode:(NSData *)anData shouldFail:(BOOL)aFlag{
    id result = TCM_BdecodedObjectWithData(anData);
    STAssertTrue(
        aFlag ? (result == nil) : (result != nil),
        @"decoding of %@",[[[NSString alloc] initWithData:anData encoding:NSMacOSRomanStringEncoding] autorelease]);
}

- (void)testBencoding {
    [self roundtripBencode:[NSNumber numberWithInt:5]];
    [self roundtripBencode:@"Sample text"];
    STAssertEqualObjects(
        TCM_BdecodedObjectWithData(TCM_BencodedObject([NSNumber numberWithFloat:2.2])),
        [NSNumber numberWithInt:[[NSNumber numberWithFloat:2.2] intValue]],
        @"round-trip bencoding of %@",[NSNumber numberWithFloat:2.2]);
    [self roundtripBencode:[NSNumber numberWithLongLong:-2147483607]];
    [self roundtripBencode:[NSArray arrayWithObjects:@"one",@"two",@"three",nil]];
    [self roundtripBencode:[NSDictionary dictionaryWithObjectsAndKeys:@"content one",@"key one",@"content 2",@"key 2",nil]];
    [self roundtripBencode:[NSArray arrayWithObjects:@"one",@"two",[NSDictionary dictionaryWithObjectsAndKeys:@"content one",@"key one",@"content 2",@"key 2",nil],nil]];
    [self roundtripBencode:[NSDictionary dictionaryWithObjectsAndKeys:@"content one",@"key one",[NSArray arrayWithObjects:@"one",@"two",@"three",nil],@"key 2",nil]];
    
    
    [self bdecode:[@":one3:twod7" dataUsingEncoding:NSMacOSRomanStringEncoding]                                                             shouldFail:YES];
    [self bdecode:[@"d7:key one11:content one5:key 2l3:one3:two5:threeee" dataUsingEncoding:NSMacOSRomanStringEncoding]                     shouldFail:NO];
    [self bdecode:[@"d7:key one11:content one:5:key 2l3:on" dataUsingEncoding:NSMacOSRomanStringEncoding]                                   shouldFail:YES];
    [self bdecode:[@"l3:one3:two3:shouldfail" dataUsingEncoding:NSMacOSRomanStringEncoding]                                                 shouldFail:YES];
    [self bdecode:[@"d3:cnti133029683e4:name4:Cecy3:uID16...A.8..........$e" dataUsingEncoding:NSMacOSRomanStringEncoding]                  shouldFail:NO];
    [self bdecode:[@"d6:rendez4:vous3:uid36:DDC5EF9E-A818-11D8-BF7B-00039398A6244:vers3:200e" dataUsingEncoding:NSMacOSRomanStringEncoding] shouldFail:NO];
}

- (void)tearDown {}

@end
