//
//  TCMPreferenceModule.h
//  SubEthaEdit
//
//  Created by Martin Ott on Thu Feb 26 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PreferencePanes/PreferencePanes.h>


@interface TCMPreferenceModule : NSResponder
{
    IBOutlet NSWindow *O_window;
    NSView *O_mainView;
    NSSize I_maxSize;
    NSSize I_minSize;
}

- (NSImage *)icon;
- (NSString *)iconLabel;
- (NSString *)identifier;

/*"Setting up the main view"*/
- (NSView *)assignMainView;
- (NSView *)loadMainView;
- (NSString *)mainNibName;
- (NSView *)mainView;
- (void)mainViewDidLoad;
- (void)setMainView:(NSView *)aView;

/*"Handling preference module selection"*/
- (void)didSelect;
- (void)willSelect;
- (void)didUnselect;
- (void)replyToShouldUnselect:(BOOL)shouldUnselect;
- (NSPreferencePaneUnselectReply)shouldUnselect;
- (void)willUnselect;

- (NSSize)maxSize;
- (NSSize)minSize;

@end
