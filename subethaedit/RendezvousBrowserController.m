//
//  RendezvousBrowserController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "RendezvousBrowserController.h"


@implementation RendezvousBrowserController
- (id)init {
    if ((self=[super init])) {
        I_tableData=[NSMutableArray new];
    }
    return self;
}

- (void)dealloc {
    [I_tableData release];
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"RendezvousBrowser";
}

-(NSMutableArray *)tableData {
    return I_tableData;
}
-(void)setTableData:(NSMutableArray *)tableData {
    [I_tableData autorelease];
    I_tableData=[tableData mutableCopy];
}

@end
