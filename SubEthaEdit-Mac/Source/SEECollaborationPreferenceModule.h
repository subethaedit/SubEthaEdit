//  SEECollaborationPreferenceModule.h
//  SubEthaEdit
//
//  Created by Lisa Brodner on 10/04/14.

#import "TCMPreferenceModule.h"
@class SEECollaborationPreferenceModule;
#import "SEEUserColorsPreviewView.h"
#import "SEEAvatarImageView.h"

@interface SEECollaborationPreferenceModule : TCMPreferenceModule

// network
@property (nonatomic, strong) IBOutlet NSButton *O_automaticallyMapPortButton;
@property (nonatomic, strong) IBOutlet NSTextField *O_localPortTextField;
@property (nonatomic, strong) IBOutlet NSTextField *O_mappingStatusTextField;
@property (nonatomic, strong) IBOutlet NSImageView *O_mappingStatusImageView;
@property (nonatomic, strong) IBOutlet NSProgressIndicator *O_mappingStatusProgressIndicator;
@property (nonatomic, strong) IBOutlet NSButton *O_disableNetworkingButton;
@property (nonatomic, strong) IBOutlet NSButton *O_invisibleOnNetworkButton;
@property (nonatomic, strong) IBOutlet NSTextField *O_invisibleOnNetworkExplanationTextField;

// me-card
@property (nonatomic, strong) IBOutlet SEEAvatarImageView *O_avatarImageView;
@property (nonatomic, strong) IBOutlet NSTextField *O_nameTextField;
@property (nonatomic, strong) IBOutlet NSTextField *O_emailTextField;

// colors
@property (nonatomic, strong) IBOutlet SEEUserColorsPreviewView *O_userColorsPreview;
@property (nonatomic, strong) IBOutlet NSButton *O_highlightChangesButton;

// localization outlet additions
@property (nonatomic, strong) IBOutlet NSTextField *O_userNameLabel;
@property (nonatomic, strong) IBOutlet NSTextField *O_userEmailLabel;
@property (nonatomic, strong) IBOutlet NSSlider *O_highlightChangesSlider;
@property (nonatomic, strong) IBOutlet NSBox *O_networkBox;
@property (nonatomic, strong) IBOutlet NSTextField *O_localPortLabel;
@property (nonatomic, strong) IBOutlet NSTextField *O_automaticallyMapPortExplanationTextField;

@property (nonatomic, strong) IBOutlet NSTextField *O_userColorLabel;
@property (nonatomic, strong) IBOutlet NSTextField *O_changesSaturationLabelPale;
@property (nonatomic, strong) IBOutlet NSTextField *O_changesSaturationLabelStrong;

// actions - network
- (IBAction)changeAutomaticallyMapPorts:(id)aSender;
- (IBAction)changeDisableNetworking:(id)aSender;
- (IBAction)changeVisiblityOnNetwork:(id)aSender;

// actions - me-card
- (IBAction)chooseImage:(id)aSender;

- (IBAction)changeName:(id)aSender;
- (IBAction)changeEmail:(id)aSender;

- (IBAction)postGeneralViewPreferencesDidChangeNotificiation:(id)aSender;
- (IBAction)updateChangesColor:(id)sender;

@end
