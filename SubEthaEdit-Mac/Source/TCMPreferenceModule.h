//  TCMPreferenceModule.h
//  SubEthaEdit
//
//  Created by Martin Ott on Thu Feb 26 2004.

#import <Foundation/Foundation.h>
#import <PreferencePanes/PreferencePanes.h>


@interface TCMPreferenceModule : NSResponder
{
    NSSize I_maxSize;
    NSSize I_minSize;
}

@property (readwrite, strong) IBOutlet NSWindow *O_window;
@property (readwrite, strong) IBOutlet NSView *mainView;

- (NSImage *)icon;
- (NSString *)iconLabel;
- (NSString *)identifier;

/*"Setting up the main view"*/
- (NSView *)assignMainView;
- (NSView *)loadMainView;
- (NSString *)mainNibName;
- (NSView *)mainView;
- (void)mainViewDidLoad;

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
