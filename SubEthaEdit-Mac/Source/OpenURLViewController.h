//  OpenURLViewController.h
//  SubEthaEdit
//
//  Created by Jan Cornelissen on 29/11/2020.

#import <Cocoa/Cocoa.h>

@interface OpenURLViewController : NSViewController

@property (nonatomic, strong) NSURL *url;

- (instancetype)initWithURL:(NSURL *)url;
@end
