#import <Foundation/Foundation.h>
#import "Controller.h"

BOOL endRunLoop = NO;

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    BOOL isRunning = YES;
    Controller *controller = [Controller new];
    NSFileHandle *standardInput = [NSFileHandle fileHandleWithStandardInput];
    [standardInput readInBackgroundAndNotify];
    
    fprintf(stdout, "xmpp> ");
    fflush(stdout);
    
    do {
        NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
        isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                             beforeDate:[NSDate distantFuture]];
        [subPool release];
    } while (isRunning && !endRunLoop);
    
    [controller release];
    [standardInput release];
    [pool release];
    return 0;
}
