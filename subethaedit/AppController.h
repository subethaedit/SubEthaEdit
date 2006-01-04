//
//  AppController.h
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


#define kKAHL 'KAHL'
#define kMOD 'MOD '


extern int const FileMenuTag   ;
extern int const EditMenuTag   ;
extern int const FileNewMenuItemTag ;
extern int const CutMenuItemTag   ;
extern int const CopyMenuItemTag  ;
extern int const CopyXHTMLMenuItemTag ;
extern int const CopyStyledMenuItemTag ;
extern int const PasteMenuItemTag ;
extern int const BlockeditMenuItemTag ;
extern int const SpellingMenuItemTag ;
extern int const SpeechMenuItemTag   ;
extern int const FormatMenuTag ;
extern int const FontMenuItemTag ;
extern int const FileEncodingsMenuItemTag ;
extern int const WindowMenuTag ;


@interface AppController : NSObject {
    BOOL I_lastShouldOpenUntitledFile;
}

+ (AppController *)sharedInstance;

- (BOOL)lastShouldOpenUntitledFile;

- (IBAction)undo:(id)aSender;
- (IBAction)redo:(id)aSender;

- (IBAction)purchaseSubEthaEdit:(id)sender;
- (IBAction)enterSerialNumber:(id)sender;

- (IBAction)showLicense:(id)sender;
- (IBAction)showAcknowledgements:(id)sender;
- (IBAction)showRegExHelp:(id)sender;
- (IBAction)showReleaseNotes:(id)sender;
- (IBAction)visitWebsite:(id)sender;
- (IBAction)reportBug:(id)sender;

@end
