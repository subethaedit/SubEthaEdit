//
//  GeneralPreferences.h
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 29 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMPreferenceModule.h"
#import "PreferenceKeys.h"

@class DocumentModePopUpButton;

@interface GeneralPreferences : TCMPreferenceModule {
    IBOutlet DocumentModePopUpButton *O_modeForNewDocumentsPopUpButton;
}

@property (nonatomic, strong) IBOutlet NSButton *O_highlightLocalChangesButton;
- (IBAction)toggleLocalHighlightDefault:(id)aSender;

- (IBAction)postGeneralViewPreferencesDidChangeNotificiation:(id)aSender;
- (IBAction)changeModeForNewDocuments:(id)aSender;
@end
