//
//  SEEPlainTextParticipantViewController.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 27.01.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEPlainTextParticipantViewController.h"
#import "TCMMMUser.h"

@interface SEEPlainTextParticipantViewController ()
@property (nonatomic, readwrite, strong) TCMMMUser *participant;

@property (nonatomic, strong) IBOutlet NSView *actionOverlayOutlet;
@property (nonatomic, weak) IBOutlet NSTextField *nameLabelOutlet;
@property (nonatomic, weak) IBOutlet NSButton *userViewButtonOutlet;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *connectinProgressIndicatorOutlet;
@end

@implementation SEEPlainTextParticipantViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)loadView {
	[super loadView];

	NSButton *userViewButton = self.userViewButtonOutlet;
	NSRect userViewButtonFrame = userViewButton.frame;
	userViewButton.image = self.participant.image;
	userViewButton.layer.cornerRadius = NSHeight(userViewButtonFrame) / 2.0;
	userViewButton.layer.borderWidth = 3.0;

	if (self.user.isMe) {
		userViewButton.alphaValue = 0.8;
	}

	CGFloat hueValue = [[self.participant.properties objectForKey:@"Hue"] doubleValue] / 255.0;
	userViewButton.layer.borderColor = [[NSColor colorWithCalibratedHue:hueValue saturation:0.8 brightness:1.0 alpha:0.6] CGColor];
}

@end
