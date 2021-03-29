//
//  DocumentModePopUpButton.h
//  SubEthaEdit
//
//  Created by dom on 29.03.2021.
//  Copyright © 2021 SubEthaEdit Contributors. All rights reserved.
//

#import <Cocoa/Cocoa.h>

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

