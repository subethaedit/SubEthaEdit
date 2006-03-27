//
//  DocumentModeManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DocumentMode.h"

#define BASEMODEIDENTIFIER @"SEEMode.Base"
#define AUTOMATICMODEIDENTIFIER @"SEEMode.Automatic"


@interface DocumentModePopUpButton : NSPopUpButton {
    BOOL I_automaticMode;
}

- (void)setHasAutomaticMode:(BOOL)aFlag;
- (DocumentMode *)selectedMode;
- (void)setSelectedMode:(DocumentMode *)aMode;
- (NSString *)selectedModeIdentifier;
- (void)setSelectedModeIdentifier:(NSString *)aModeIdentifier;
- (void)documentModeListChanged:(NSNotification *)notification;
@end

@interface DocumentModeMenu : NSMenu {
    SEL I_action;
    BOOL I_alternateDisplay;
}
- (void)configureWithAction:(SEL)aSelector alternateDisplay:(BOOL)aFlag;
@end

@interface DocumentModeManager : NSObject {
    NSMutableDictionary *I_modeBundles;
    NSMutableDictionary *I_documentModesByIdentifier;
	NSMutableDictionary *I_modeIdentifiersByExtension;
	NSMutableArray      *I_modeIdentifiersTagArray;
}

+ (DocumentModeManager *)sharedInstance;
+ (DocumentMode *)baseMode;
+ (NSString *)xmlFileRepresentationOfAllStyles;

- (DocumentMode *)baseMode;
- (DocumentMode *)modeForNewDocuments;
- (DocumentMode *)documentModeForIdentifier:(NSString *)anIdentifier;
- (DocumentMode *)documentModeForExtension:(NSString *)anExtension;
- (DocumentMode *)documentModeForName:(NSString *)aName;
- (NSString *)documentModeIdentifierForTag:(int)aTag;
- (BOOL)documentModeAvailableModeIdentifier:(NSString *)anIdentifier;
- (int)tagForDocumentModeIdentifier:(NSString *)anIdentifier;
- (NSDictionary *)availableModes;

- (IBAction)reloadDocumentModes:(id)aSender;

@end
