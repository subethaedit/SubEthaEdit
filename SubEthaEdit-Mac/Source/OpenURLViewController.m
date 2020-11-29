//
//  OpenURLViewController.m
//  SubEthaEdit
//
//  Created by Jan Cornelissen on 29/11/2020.
//  Copyright © 2020 SubEthaEdit Contributors. All rights reserved.
//

#import "OpenURLViewController.h"

@implementation OpenURLViewController

- (instancetype)initWithURL:(NSURL *)anURLToOpen {
    self=[super initWithNibName:@"OpenURLViewController" bundle:nil];
    [self setURLToOpen:anURLToOpen];
    return self;
}

- (IBAction)openURLAction:(id)aSender {
    NSLog(@"%s now i would open: %@",__FUNCTION__,[self URLToOpen]);
    [[NSWorkspace sharedWorkspace] openURL:[self URLToOpen]];
}

@end
