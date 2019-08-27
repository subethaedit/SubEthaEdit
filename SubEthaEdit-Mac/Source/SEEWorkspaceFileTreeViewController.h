//
//  SEEWorkspaceFileTreeViewController.h
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 03.08.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SEEWorkspace;



@interface SEEWorkspaceFileTreeViewController : NSViewController <NSOutlineViewDelegate>

- (instancetype)initWithWorkspace:(SEEWorkspace *)workspace;

@property (nonatomic, weak) SEEWorkspace *workspace;
@end


