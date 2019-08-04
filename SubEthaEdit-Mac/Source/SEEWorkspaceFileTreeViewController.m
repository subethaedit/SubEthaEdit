//
//  SEEWorkspaceFileTreeViewController.m
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 03.08.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import "SEEWorkspaceFileTreeViewController.h"

@interface SEEWorkspaceFileTreeViewController ()

@property (nonatomic, weak) IBOutlet NSTreeController *treeController;

@end

@implementation SEEWorkspaceFileTreeViewController

- (instancetype)initWithWorkspace:(SEEWorkspace *)workspace {
    self = [super initWithNibName:@"SEEWorkspaceFileTreeViewController" bundle:nil];
    if (self) {
        self.workspace = workspace;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

@end
