//
//  SEEOpenURLView.h
//  SubEthaEdit
//
//  Created by Jan Cornelissen on 29/11/2020.
//  Copyright © 2020 SubEthaEdit Contributors. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface OpenURLViewController : NSViewController

@property (nonatomic, strong) NSURL *URLToOpen;

- (instancetype)initWithURL:(NSURL *)anURLToOpen;

@end
