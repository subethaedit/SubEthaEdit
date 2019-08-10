//  GlassButton.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 18.09.06.

#import "HUDButton.h"
#import "HUDButtonCell.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation HUDButton

+ (void)initialize {
    if (self == [HUDButton class]) {
        [self setCellClass:[HUDButtonCell class]];
    }
}

+ (Class)cellClass {
    return [HUDButtonCell class];
}

- (instancetype)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    NSMutableData *data=[NSMutableData data];
    NSKeyedArchiver *archiver=[[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver setClassName:NSStringFromClass([[self class] cellClass])
              forClass:[NSButtonCell class]]; // <--------------------- !!!Replace if reuse!!!
    [archiver encodeObject:[self cell] forKey:@"MyCell"];
    [archiver finishEncoding];
    
    NSKeyedUnarchiver *unarchiver=[[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    [unarchiver setClass:[[self class] cellClass] forClassName:NSStringFromClass([[super class] cellClass])];
    [self setCell:[unarchiver decodeObjectForKey:@"MyCell"]];
    [unarchiver finishDecoding];

    return self;
}

@end
