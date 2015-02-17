//
//  PreferenceKeys.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 09.04.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import "PreferenceKeys.h"

NSString * const GeneralViewPreferencesDidChangeNotificiation =
               @"GeneralViewPreferencesDidChangeNotificiation";

NSString * const MyColorHuePreferenceKey                    = @"MyColorHue";
NSString * const CustomMyColorHuePreferenceKey              = @"CustomMyColorHue";
NSString * const SelectionSaturationPreferenceKey           = @"MySelectionSaturation";
NSString * const ChangesSaturationPreferenceKey             = @"MyChangesSaturation";
NSString * const HighlightChangesPreferenceKey              = @"HighlightChanges";
NSString * const HighlightChangesAlonePreferenceKey         = @"HighlightChangesAlone";
NSString * const ModeForNewDocumentsPreferenceKey           = @"ModeForNewDocuments";
NSString * const AdditionalShownPathComponentsPreferenceKey = @"AdditionalShownPathComponents";
NSString * const SelectedMyColorPreferenceKey               = @"SelectedMyColor";
NSString * const MyNamePreferenceKey                        = @"MyName";
NSString * const MyAIMPreferenceKey                         = @"MyAIM";
NSString * const MyEmailPreferenceKey                       = @"MyEmail";
NSString * const MyAIMIdentifierPreferenceKey               = @"MyAIMIdentifier";
NSString * const MyEmailIdentifierPreferenceKey             = @"MyEmailIdentifier";
NSString * const MyAIMsPreferenceKey                        = @"MyAIMs";
NSString * const MyEmailsPreferenceKey                      = @"MyEmails";
NSString * const SynthesiseFontsPreferenceKey               = @"SynthesiseFonts";

NSString * const DidUpdateOpenDocumentOnStartPreferenceKey  = @"DidUpdateOpenDocumentOnStart"; // upgrading from old version
NSString * const OpenDocumentOnStartPreferenceKey           = @"OpenDocumentOnStart"; // deprecated old version
NSString * const OpenUntitledDocumentOnStartupPreferenceKey = @"OpenUntitledDocumentOnStartup";
NSString * const OpenDocumentHubOnStartupPreferenceKey      = @"OpenDocumentHubOnStartup";

NSString * const kSEEDefaultsKeyOpenNewDocumentInTab           = @"OpenNewDocumentInTab";
NSString * const kSEEDefaultsKeyAlwaysShowTabBar               = @"AlwaysShowTabBar";
NSString * const kSEEDefaultsKeyDontSaveDocumentStateInXattrs  = @"DontSaveDocumentStateInXattrs";

NSString * const kSEEDefaultsKeyUseTemporaryKeychainForTLS     = @"UseTemporaryKeychainForTLS";
NSString * const kSEEDefaultsKeyEnableTLS                      = @"EnableTLS";

NSString * const kSEELastKnownBundleVersion = @"SEELastKnownBundleVersion";

NSString * const DocumentStateSaveAndLoadWindowPositionKey = @"DocumentStateSaveAndLoadWindowPosition" ;
NSString * const DocumentStateSaveAndLoadTabSettingKey     = @"DocumentStateSaveAndLoadTabSetting"     ;
NSString * const DocumentStateSaveAndLoadWrapSettingKey    = @"DocumentStateSaveAndLoadWrapSetting"    ;
NSString * const DocumentStateSaveAndLoadDocumentModeKey   = @"DocumentStateSaveAndLoadDocumentMode"   ;
NSString * const DocumentStateSaveAndLoadSelectionKey      = @"DocumentStateSaveAndLoadSelection"      ;
NSString * const DocumentStateSaveAndLoadFoldingStateKey   = @"DocumentStateSaveAndLoadFoldingState"   ;
