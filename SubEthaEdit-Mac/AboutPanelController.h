//
//  AboutPanelController.h
//  SubEthaEdit
//
//  Created by Martin Ott on Thu May 13 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>

@interface AboutPanelController : NSWindowController

@property (nonatomic, strong) IBOutlet NSImageView *O_appIconView;
@property (nonatomic, strong) IBOutlet NSTextField *O_legalTextField;
@property (nonatomic, strong) IBOutlet NSTextField *O_versionField;
@property (nonatomic, strong) IBOutlet NSTextField *O_ogreVersionField;

@end
