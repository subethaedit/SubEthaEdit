//
//  UserStatisticsController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 21.08.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "UserStatisticsController.h"
#import "HUDStatisticPersonCell.h"


@implementation UserStatisticsController

- (NSString *)windowNibName {
    return @"UserStatistics";
}

- (void)windowDidLoad {
    [[O_userTableView tableColumnWithIdentifier:@"entries"] setDataCell:[[HUDStatisticPersonCell alloc] init]];
}

@end
