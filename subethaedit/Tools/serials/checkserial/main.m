#import <Foundation/Foundation.h>

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSString *serial = [NSString stringWithCString:argv[1]];
    
    if ([serial isValidSerial]) NSLog(@"Serial %@ is valid",serial);
    else NSLog(@"Serial %@ is invalid",serial);
    
    [pool release];
    return 0;
}
