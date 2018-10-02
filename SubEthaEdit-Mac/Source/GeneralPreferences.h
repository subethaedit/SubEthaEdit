//  GeneralPreferences.h
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 29 2004.

#import <Foundation/Foundation.h>
#import "TCMPreferenceModule.h"
#import "PreferenceKeys.h"

@class DocumentModePopUpButton;

@interface GeneralPreferences : TCMPreferenceModule

@property (nonatomic, strong) IBOutlet NSButton *O_highlightLocalChangesButton;
- (IBAction)toggleLocalHighlightDefault:(id)aSender;

@property (nonatomic, strong) IBOutlet DocumentModePopUpButton *O_modeForNewDocumentsPopUpButton;
- (IBAction)postGeneralViewPreferencesDidChangeNotificiation:(id)aSender;
- (IBAction)changeModeForNewDocuments:(id)aSender;
@end
