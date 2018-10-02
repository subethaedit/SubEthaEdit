//
//  PreferenceKeys.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 09.04.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString * const GeneralViewPreferencesDidChangeNotificiation;


extern NSString * const MyColorHuePreferenceKey;
extern NSString * const CustomMyColorHuePreferenceKey;
extern NSString * const SelectionSaturationPreferenceKey;
extern NSString * const ChangesSaturationPreferenceKey;
extern NSString * const HighlightChangesPreferenceKey;
extern NSString * const HighlightChangesAlonePreferenceKey;
extern NSString * const SelectedMyColorPreferenceKey;
extern NSString * const ModeForNewDocumentsPreferenceKey;
extern NSString * const AdditionalShownPathComponentsPreferenceKey;
extern NSString * const MyNamePreferenceKey;
extern NSString * const MyAIMPreferenceKey ;
extern NSString * const MyEmailPreferenceKey;
extern NSString * const MyAIMIdentifierPreferenceKey;
extern NSString * const MyEmailIdentifierPreferenceKey;
extern NSString * const MyNamesPreferenceKey;
extern NSString * const MyAIMsPreferenceKey;
extern NSString * const MyEmailsPreferenceKey;
extern NSString * const SynthesiseFontsPreferenceKey;

extern NSString * const DidUpdateOpenDocumentOnStartPreferenceKey;
extern NSString * const OpenDocumentOnStartPreferenceKey; // deprecated use the 2 keys below
extern NSString * const OpenUntitledDocumentOnStartupPreferenceKey;
extern NSString * const OpenDocumentHubOnStartupPreferenceKey;

extern NSString * const kSEEDefaultsKeyOpenNewDocumentInTab;
extern NSString * const kSEEDefaultsKeyAlwaysShowTabBar;
extern NSString * const kSEEDefaultsKeyDontSaveDocumentStateInXattrs;
extern NSString * const kSEEDefaultsKeyUseTemporaryKeychainForTLS;
extern NSString * const kSEEDefaultsKeyEnableTLS;

extern NSString * const kSEELastKnownBundleVersion;

extern NSString * const DocumentStateSaveAndLoadWindowPositionKey;
extern NSString * const DocumentStateSaveAndLoadTabSettingKey;
extern NSString * const DocumentStateSaveAndLoadWrapSettingKey;
extern NSString * const DocumentStateSaveAndLoadDocumentModeKey;
extern NSString * const DocumentStateSaveAndLoadSelectionKey;
extern NSString * const DocumentStateSaveAndLoadFoldingStateKey;
