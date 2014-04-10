//
//  SEECollaborationPreferenceModule.h
//  SubEthaEdit
//
//  Created by Lisa Brodner on 10/04/14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import "TCMPreferenceModule.h"

@interface SEECollaborationPreferenceModule : TCMPreferenceModule

@property (nonatomic, strong) IBOutlet NSButton *O_automaticallyMapPortButton;
@property (nonatomic, strong) IBOutlet NSTextField *O_localPortTextField;
@property (nonatomic, strong) IBOutlet NSTextField *O_mappingStatusTextField;
@property (nonatomic, strong) IBOutlet NSImageView *O_mappingStatusImageView;
@property (nonatomic, strong) IBOutlet NSProgressIndicator *O_mappingStatusProgressIndicator;

@property (nonatomic, readonly) NSString *localizedNetworkBoxLabelText;
@property (nonatomic, readonly) NSString *localizedLocalPortLabelText;
@property (nonatomic, readonly) NSString *localizedAutomaticallyMapPortsLabelText;
@property (nonatomic, readonly) NSString *localizedAutomaticallyMapPortsExplanationText;
@property (nonatomic, readonly) NSString *localizedAutomaticallyMapPortsToolTipText;

- (IBAction)changeAutomaticallyMapPorts:(id)aSender;

@end
