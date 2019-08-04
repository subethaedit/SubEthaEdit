//
//  SEEWorkspaceFileTreeViewController.h
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 03.08.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SEEWorkspace;

NS_ASSUME_NONNULL_BEGIN

@interface SEEWorkspaceFileTreeViewController : NSViewController

@property (nonatomic, weak) SEEWorkspace *workspace;
@end

NS_ASSUME_NONNULL_END
