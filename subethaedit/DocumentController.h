//
//  DocumentController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Mar 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCMMMSession;
@class EncodingPopUpButton;
@class DocumentModePopUpButton;

@interface DocumentController : NSDocumentController {
    IBOutlet NSView *O_openPanelAccessoryView;
    IBOutlet EncodingPopUpButton *O_encodingPopUpButton;
    IBOutlet DocumentModePopUpButton *O_modePopUpButton;
    
    NSStringEncoding I_encodingFromLastRunOpenPanel;
    NSString *I_modeIdentifierFromLastRunOpenPanel;
    NSMutableArray *I_fileNamesFromLastRunOpenPanel;
}

+ (DocumentController *)sharedInstance;

- (void)addDocumentWithSession:(TCMMMSession *)aSession;

- (NSStringEncoding)encodingFromLastRunOpenPanel;
- (NSString *)modeIdentifierFromLastRunOpenPanel;
- (BOOL)isDocumentFromLastRunOpenPanel:(NSDocument *)aDocument;

@end
