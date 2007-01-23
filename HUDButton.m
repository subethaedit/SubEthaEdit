//
//  GlassButton.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 18.09.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "HUDButton.h"
#import "HUDButtonCell.h"


@implementation HUDButton

+ (void)initialize {
    if (self == [HUDButton class]) {
        [self setCellClass:[HUDButtonCell class]];
    }
}

+ (Class)cellClass {
    return [HUDButtonCell class];
}

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    NSMutableData *data=[NSMutableData data];
    NSKeyedArchiver *archiver=[[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver setClassName:NSStringFromClass([[self class] cellClass])
              forClass:[NSButtonCell class]]; // <--------------------- !!!Replace if reuse!!!
    [archiver encodeObject:[self cell] forKey:@"MyCell"];
    [archiver finishEncoding];
    [archiver autorelease];
    
    NSKeyedUnarchiver *unarchiver=[[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    [unarchiver setClass:[[self class] cellClass] forClassName:NSStringFromClass([[super class] cellClass])];
    [self setCell:[unarchiver decodeObjectForKey:@"MyCell"]];
    [unarchiver finishDecoding];
    [unarchiver autorelease];

    return self;
}

@end
