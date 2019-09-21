//  SEEParticipantViewController.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 27.01.14.

#import <Cocoa/Cocoa.h>

@class PlainTextWindowControllerTabContext, TCMMMUser;

typedef NS_ENUM(NSInteger, SEEParticipantViewMode) {
	SEEParticipantViewModeUnknown = -1,
	SEEParticipantViewModeParticipant = 0,
	SEEParticipantViewModeInvited,
	SEEParticipantViewModePending
};

@interface SEEParticipantViewController : NSViewController <NSPopoverDelegate>

@property (nonatomic, readonly) SEEParticipantViewMode viewMode;
@property (nonatomic, readonly, strong) TCMMMUser *participant;
@property (nonatomic) BOOL isParticipantFollowed;

@property (nonatomic, readonly, strong) NSColor *popoverTextColor;

- (instancetype)initWithParticipant:(TCMMMUser *)aParticipant tabContext:(PlainTextWindowControllerTabContext *)aTabContext inMode:(SEEParticipantViewMode)aMode;

- (void)updateColorsForIsDarkBackground:(BOOL)isDark;

@end
