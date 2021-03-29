//  DocumentModePopUpButton.m
//  SubEthaEdit
//
//  Created by dom on 29.03.2021.

#import "DocumentMode.h"
#import "DocumentModeManager.h"
#import "DocumentModePopUpButton.h"

@implementation DocumentModePopUpButton

/* Replace the cell, sign up for notifications.
*/
- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        I_automaticMode = NO;
    }
    return self;
}

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentModeListChanged:) name:@"DocumentModeListChanged" object:nil];
    [[DocumentModeManager sharedInstance] setupPopUp:self selectedModeIdentifier:BASEMODEIDENTIFIER automaticMode:I_automaticMode];
}

- (void)setHasAutomaticMode:(BOOL)aFlag {
    I_automaticMode = aFlag;
    [self documentModeListChanged:[NSNotification notificationWithName:@"DocumentModeListChanged" object:self]];
}

- (NSString *)selectedModeIdentifier {
    DocumentModeManager *manager=[DocumentModeManager sharedInstance];
    return [manager documentModeIdentifierForTag:[[self selectedItem] tag]];
}

- (void)setSelectedModeIdentifier:(NSString *)aModeIdentifier {
    int tag=[[DocumentModeManager sharedInstance] tagForDocumentModeIdentifier:aModeIdentifier];
    [self selectItemAtIndex:[[self menu] indexOfItemWithTag:tag]];
}

- (DocumentMode *)selectedMode {
    DocumentModeManager *manager=[DocumentModeManager sharedInstance];
    DocumentMode *mode = [manager documentModeForIdentifier:[manager documentModeIdentifierForTag:[[self selectedItem] tag]]];
    if (!mode) {
        mode = [DocumentModeManager baseMode];
        [self setSelectedMode:mode];
    }
    return mode;
}

- (void)setSelectedMode:(DocumentMode *)aMode {
    int tag=[[DocumentModeManager sharedInstance] tagForDocumentModeIdentifier:[[aMode bundle] bundleIdentifier]];
    [self selectItemAtIndex:[[self menu] indexOfItemWithTag:tag]];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/* Update contents based on encodings list customization
*/
- (void)documentModeListChanged:(NSNotification *)notification {
    NSString *selectedModeIdentifier=[self selectedModeIdentifier];
    if (![[DocumentModeManager sharedInstance] documentModeAvailableModeIdentifier:selectedModeIdentifier]) {
        selectedModeIdentifier=BASEMODEIDENTIFIER;
    }
    [[DocumentModeManager sharedInstance] setupPopUp:self selectedModeIdentifier:selectedModeIdentifier automaticMode:I_automaticMode];
    [self setSelectedModeIdentifier:selectedModeIdentifier];
}

@end
