//
//  AppController.m
//  CreateStringByUnicharTest
//
//  Created by Dominik Wagner on 21.07.05.
//  Copyright 2005 TheCodingMonkeys. All rights reserved.
//

#import "AppController.h"
#import "sys/time.h"

#define REPORT(format, args...) \
do { \
    [[[O_outputTextView textStorage] mutableString] appendFormat:format, ##args]; \
} while (0)

NSTimeInterval inline TimeIntervalSince1970() {
    struct timeval tv;
    gettimeofday(&tv,NULL);
    return tv.tv_sec + tv.tv_usec / (NSTimeInterval)1000000.;
}

@implementation AppController

- (void)applicationDidFinishLaunching:(id)aIgnore {
    [self testIt:self];
}

- (NSString *)prettyStringForTimeInterval:(NSTimeInterval)aTimeInterval {
    return [NSString stringWithFormat:@"%2.6fs",aTimeInterval];
}

- (IBAction)testIt:(id)aSender {
    int loopCount = [O_numberOfStringsTextField intValue];
    int loop=0;
    unichar testChar = 0x21cb;
    unichar testCharArray[] = {0x21cb,0x2024,0x2192,0x2192,0x204b,0x2014,0x00b6,0x2761,0x21ab,0x2038};
    NSTimeInterval start_time = 0;

    REPORT(@"================================================\n");


    REPORT(@"Alloc/initWithCharactersNoCopy: length: freeWhenDone:\n");
    start_time = TimeIntervalSince1970();

    for (loop=0;loop<loopCount;loop++) {
        testChar = testCharArray[loop % 10];
        NSString *string=[[NSString alloc] initWithCharactersNoCopy:&testChar length:1 freeWhenDone:NO];
        [string release];
    }
    REPORT(@"Time taken: %@\n\n",[self prettyStringForTimeInterval:TimeIntervalSince1970()-start_time]);

    REPORT(@"NSMutableString appendWithFormat:\n");
    start_time = TimeIntervalSince1970();

    NSMutableString *mutableString = [NSMutableString new];
    for (loop=0;loop<loopCount;loop++) {
        testChar = testCharArray[loop % 10];
        [mutableString setString:@""];
        [mutableString appendFormat:@"%C",testChar];
    }
    [mutableString release];
    REPORT(@"Time taken: %@\n\n",[self prettyStringForTimeInterval:TimeIntervalSince1970()-start_time]);

    REPORT(@"alloc/initWithFormat:\n");
    start_time = TimeIntervalSince1970();

    for (loop=0;loop<loopCount;loop++) {
        testChar = testCharArray[loop % 10];
        NSString *string=[[NSString alloc] initWithFormat:@"%C",testChar];
        [string release];
    }
    REPORT(@"Time taken: %@\n\n",[self prettyStringForTimeInterval:TimeIntervalSince1970()-start_time]);

    REPORT(@"================================================\n");


}

@end
