#import "Controller.h"
#import "PortMapper.h"

@implementation Controller

- (void) awakeFromNib {

    NSLog(@"Foo");
    PortMapper *pm = [PortMapper sharedInstance];
    [pm doSomething];

}



@end
