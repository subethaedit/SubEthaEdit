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
    IBOutlet NSButton *O_higlightChangesButton;
    IBOutlet NSButton *O_alsoInLocalDocumentsButton;
    
    IBOutlet NSButton *O_openNewDocumentAtStartupButton;
    IBOutlet NSPopUpButton *O_defaultModePopUpButton;
    
    IBOutlet DocumentModePopUpButton *O_modeForNewDocumentsPopUpButton;
}

- (IBAction)postGeneralViewPreferencesDidChangeNotificiation:(id)aSender;
- (IBAction)changeModeForNewDocuments:(id)aSender;
@end
