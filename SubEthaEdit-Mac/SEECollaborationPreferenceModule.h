//
//  SEECollaborationPreferenceModule.h
//  SubEthaEdit
//
//  Created by Lisa Brodner on 10/04/14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import "TCMPreferenceModule.h"
@class SEECollaborationPreferenceModule;
#import "PCRolloverImageView.h"

@interface SEECollaborationPreferenceModule : TCMPreferenceModule

// network
@property (nonatomic, strong) IBOutlet NSButton *O_automaticallyMapPortButton;
@property (nonatomic, strong) IBOutlet NSTextField *O_localPortTextField;
@property (nonatomic, strong) IBOutlet NSTextField *O_mappingStatusTextField;
@property (nonatomic, strong) IBOutlet NSImageView *O_mappingStatusImageView;
@property (nonatomic, strong) IBOutlet NSProgressIndicator *O_mappingStatusProgressIndicator;

// me-card
@property (nonatomic, strong) IBOutlet NSButton *O_useAddressbookButton;
@property (nonatomic, strong) IBOutlet PCRolloverImageView *O_pictureImageView;
@property (nonatomic, strong) IBOutlet NSTextField *O_nameTextField;
@property (nonatomic, strong) IBOutlet NSComboBox  *O_emailComboBox;


// localization
@property (nonatomic, readonly) NSString *localizedNetworkBoxLabelText;
@property (nonatomic, readonly) NSString *localizedLocalPortLabelText;
@property (nonatomic, readonly) NSString *localizedAutomaticallyMapPortsLabelText;
@property (nonatomic, readonly) NSString *localizedAutomaticallyMapPortsExplanationText;
@property (nonatomic, readonly) NSString *localizedAutomaticallyMapPortsToolTipText;

// actions - network
- (IBAction)changeAutomaticallyMapPorts:(id)aSender;

// actions - me-card
- (IBAction)useAddressBookImage:(id)aSender;
- (IBAction)chooseImage:(id)aSender;
- (IBAction)clearImage:(id)aSender;
- (IBAction)takeImageFromImageView:(id)aSender;

- (IBAction)changeName:(id)aSender;
- (IBAction)changeEmail:(id)aSender;

@end
