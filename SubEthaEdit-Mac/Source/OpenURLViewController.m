//  OpenURLViewController.m
//  SubEthaEdit
//
//  Created by Jan Cornelissen on 29/11/2020.

#import "OpenURLViewController.h"

@implementation OpenURLViewController

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super initWithNibName:@"OpenURLViewController" bundle:nil]) {
        self.url = url;
    }
    return self;
}

- (IBAction)openURLAction:(id)sender {
    // NSLog(@"%s now I would open: %@",__FUNCTION__,[self URLToOpen]);
    [[NSWorkspace sharedWorkspace] openURL:self.url];
}

@end
