//
//  SEEParticipantViewController.m
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

#import "SEEParticipantViewController.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"

@interface SEEParticipantViewController ()
@property (nonatomic, readwrite, strong) TCMMMUser *participant;

@property (nonatomic, strong) IBOutlet NSView *participantViewOutlet;
@property (nonatomic, weak) IBOutlet NSTextField *nameLabelOutlet;
@property (nonatomic, weak) IBOutlet NSButton *userViewButtonOutlet;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *connectingProgressIndicatorOutlet;

@property (nonatomic, strong) IBOutlet NSView *actionOverlayOutlet;
@property (nonatomic, weak) IBOutlet NSButton *closeConnectionButtonOutlet;
@property (nonatomic, weak) IBOutlet NSButton *toggleEditModeButtonOutlet;
@property (nonatomic, weak) IBOutlet NSButton *toggleFollowButtonOutlet;

@end

@implementation SEEParticipantViewController

- (id)initWithParticipant:(TCMMMUser *)aParticipant
{
    self = [super initWithNibName:@"SEEParticipantView" bundle:nil];
    if (self) {
		self.participant = aParticipant;
    }
    return self;
}

- (void)loadView {
	[super loadView];

	NSButton *userViewButton = self.userViewButtonOutlet;
	NSRect userViewButtonFrame = userViewButton.frame;
	NSImage *userImage = self.participant.image;
	if (userImage) {
		userViewButton.image = self.participant.image;
	}
	userViewButton.layer.cornerRadius = NSHeight(userViewButtonFrame) / 2.0;
	userViewButton.layer.borderWidth = 3.0;

	CGFloat hueValue = [[self.participant.properties objectForKey:@"Hue"] doubleValue] / 255.0;
	userViewButton.layer.borderColor = [[NSColor colorWithCalibratedHue:hueValue saturation:0.8 brightness:1.0 alpha:0.8] CGColor];

	NSTextField *nameLabel = self.nameLabelOutlet;
	nameLabel.stringValue = self.participant.name;

	NSButton *closeConnectionButton = self.closeConnectionButtonOutlet;
	closeConnectionButton.image = [NSImage pdfBasedImageNamed:@"SharingIconCloseCross"TCM_PDFIMAGE_SEP@"16"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_NORMAL];

	NSButton *toggleEditModeButton = self.toggleEditModeButtonOutlet;
	toggleEditModeButton.image = [NSImage pdfBasedImageNamed:@"SharingIconReadOnly"TCM_PDFIMAGE_SEP@"16"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_NORMAL];
	toggleEditModeButton.alternateImage = [NSImage pdfBasedImageNamed:@"SharingIconWrite"TCM_PDFIMAGE_SEP@"16"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_NORMAL];

	NSButton *toggleFollowButton = self.toggleFollowButtonOutlet;
	toggleFollowButton.image = [NSImage pdfBasedImageNamed:@"SharingIconEye"TCM_PDFIMAGE_SEP@"16"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_NORMAL];
	toggleFollowButton.alternateImage = [NSImage pdfBasedImageNamed:@"SharingIconEye"TCM_PDFIMAGE_SEP@"16"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_SELECTED];

	if (self.participant.isMe) {
		self.actionOverlayOutlet.hidden = YES;
		self.actionOverlayOutlet = nil;
	} else {
		// install tracking for action overlay
		[self.participantViewOutlet addTrackingArea:[[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingMouseEnteredAndExited|NSTrackingActiveInKeyWindow|NSTrackingInVisibleRect owner:self userInfo:nil]];
	}
}

- (void)mouseEntered:(NSEvent *)theEvent {
	self.actionOverlayOutlet.hidden = NO;
}

- (void)mouseExited:(NSEvent *)theEvent {
	self.actionOverlayOutlet.hidden = YES;
}

- (IBAction)userViewButtonClicked:(id)sender {
}

- (void)updateForInvitationState {
	self.connectingProgressIndicatorOutlet.usesThreadedAnimation = YES;
	[self.connectingProgressIndicatorOutlet startAnimation:self];
	self.nameLabelOutlet.alphaValue = 0.8;
	self.userViewButtonOutlet.alphaValue = 0.6;
}

@end
