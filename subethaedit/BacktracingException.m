//
//  BacktracingException.m
//  Fez
//
//  Created by Jens Alfke on Fri Mar 14 2003.
//  Copyright (c) 2003 Apple Computer, Inc.. All rights reserved.
//


#import "BacktracingException.h"

//#import <vmutils/vmutils.h>
extern NSArray * StackSymbols(BOOL flag) __attribute__((weak_import));

#define kMaxCrawlDepth 15	// Max number of stack frames to print

@implementation BacktracingException


SignificantRaiseHandler sHandler;


+ (void) install
{
    [self poseAsClass: [NSException class]];
}


- (id)initWithName:(NSString *)aName reason:(NSString *)aReason userInfo:(NSDictionary *)aUserInfo;
{
    // Semi-kludge: We do not log certain NSPort exceptions, because they get raised a lot,
    // and handled, in the normal operation of FZNotifier and do not represent errors.
    
    if( ! [NSPortTimeoutException isEqualToString: aName]
            && ! [NSInvalidSendPortException isEqualToString: aName]
            && ! [NSPortSendException isEqualToString: aName] ) {
        // Add an empty but mutable backtrace string to the userInfo dictionary:
        NSMutableDictionary *newInfo;
        if( aUserInfo )
            newInfo = [aUserInfo mutableCopy];
        else
            newInfo = [[NSMutableDictionary alloc] init];
        [newInfo setObject: [NSMutableString string] forKey: @"_Backtrace_"];
        aUserInfo = [newInfo autorelease];
    }
    return [super initWithName: aName reason: aReason userInfo: aUserInfo];
}


- (NSString*) backtrace
{
    return [[self userInfo] objectForKey: @"_Backtrace_"];
}


void SignificantRaise( NSException *x )
{
    // This is broken out as a function to make it easy to set a breakpoint on in gdb.
    if( sHandler )
        sHandler(x);
}


- (void)raise
{
    NSMutableString *backtrace = (NSMutableString*) [self backtrace];
    if( backtrace && [backtrace length]==0 ) {
        // Fill in the backtrace now, but only the first time I'm raised:
        [backtrace setString: [BacktracingException backtraceSkippingFrames: 0]];
		NSLog(@"*** NSEXCEPTION RAISED ***\n\t%@: %@\n%@", [self name],[self reason],backtrace);
        SignificantRaise(self);
    }
    [super raise];
}


- (void) raiseWithoutReporting
{
    [super raise];
}


+ (void) setSignificantRaiseHandler: (SignificantRaiseHandler)handler;
{
    sHandler = handler;
}


+ (NSString*) backtraceSkippingFrames: (int)skip
{
    NSMutableString *out = [[NSMutableString alloc] initWithCapacity: 1024];
	
    NSArray *symbols;
	if (StackSymbols != NULL) {
        symbols = (NSArray*) StackSymbols(YES);
    } else {
        symbols = [NSArray array];
    }
    // Append all the symbols to the string, one per line.
    // Skip leading stack frames from NSException or NSAssertionHandler; they're not interesting.
    // Similarly, skip anything after 'NSApplicationMain' or 'main', as it's also not interesting.
    unsigned int i, nPrinted=0;
    unsigned int symbolsCount = [symbols count];
    for( i=skip+1/*2*/; i<symbolsCount; i++ ) {
        if( nPrinted >= kMaxCrawlDepth ) {
            [out appendString: @"\t...more...\n"];
            break;
        }
        NSString *symbol = [symbols objectAtIndex: i];
        if( nPrinted>0 || ! ([symbol hasPrefix: @"+[NSException "] || [symbol hasPrefix: @"-[NSAssertionHandler "]) ) {
            [out appendString: @"\t"];
            [out appendString: symbol];
            [out appendString: @"\n"];
            if( [@"main" isEqualToString: symbol] || [@"NSApplicationMain" isEqualToString: symbol] )
                break;
            nPrinted++;
        }
    }
    return [out autorelease];
}


+ (void) logBacktraceSkippingFrames: (int)skip withMessage: (NSString*)message
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *backtrace = [self backtraceSkippingFrames: skip/*+1*/];
    if( message )
        NSLog(message);
    fprintf(stderr, [backtrace UTF8String]);
    [pool release];
}


+ (NSString*) backtrace
{
    return [self backtraceSkippingFrames: 0];
}


+ (void) logBacktraceWithMessage: (NSString*)message
{
    [self logBacktraceSkippingFrames: 0 withMessage: message];
}


@end
