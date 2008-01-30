//
//  AppController.m
//  PortMap
//
//  Created by Dominik Wagner on 25.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "AppController.h"


@implementation AppController
- (IBAction)refresh:(id)aSender {
    [O_mappingsArrayController add:aSender];
}

@end
