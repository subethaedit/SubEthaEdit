//
//  TCMApplication.m
//  SubEthaEdit
//
//  Created by Martin Ott on Thu Nov 4 2004.
//  Copyright 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMApplication.h"

#ifndef TCM_NO_DEBUG
#import <ExceptionHandling/NSExceptionHandler.h>
#endif

@implementation TCMApplication

#ifndef TCM_NO_DEBUG

- (NSString *)TCM_stringWithStackTraceOfException:(NSException *)exception {
    NSMutableString *string = [NSMutableString string];
    NSString *stackTrace = [[exception userInfo] objectForKey:NSStackTraceKey];
    NSLog(@"stackTrace: %@", stackTrace);
    NSString *str = [NSString stringWithFormat:@"/usr/bin/atos -p %d %@ | tail -n +3 | head -n +%d | c++filt | cat -n",
        [[NSProcessInfo processInfo] processIdentifier],
        stackTrace,
        ([[stackTrace componentsSeparatedByString:@"  "] count] - 4)];
    FILE *file = popen([str UTF8String], "r");

    if(file) {
        char buffer[512];
        size_t length;

        while((length = fread(buffer, 1, sizeof(buffer), file))) {
            NSString *bufferString = [[NSString alloc] initWithBytes:buffer length:length encoding:NSUTF8StringEncoding];
            [string appendString:bufferString];
            [bufferString release];
        }

        pclose(file);
    }
    
    return string;
}

#endif


- (void)reportException:(NSException *)anException {
    [super reportException:anException];
#ifndef TCM_NO_DEBUG
    NSString *stackTrace = [self TCM_stringWithStackTraceOfException:anException];
    NSLog(@"Backtrace:\n%@", stackTrace);
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert setMessageText:@"Exception raised"];
    [alert setInformativeText:[NSString stringWithFormat:@"Name: %@\nReason: %@\nBacktrace:\n%@", [anException name], [anException reason], stackTrace]];
    [alert addButtonWithTitle:@"OK"];
    (void)[alert runModal];
    [alert release];
#endif
}

@end
