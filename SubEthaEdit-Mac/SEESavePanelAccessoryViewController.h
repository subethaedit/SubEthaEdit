//
//  SEESavePanelAccessoryViewController.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.10.13.
//  Copyright (c) 2013 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EncodingPopUpButton, PlainTextDocument;

@interface SEESavePanelAccessoryViewController : NSViewController

@property (nonatomic, readwrite, weak) IBOutlet EncodingPopUpButton *encodingPopUpButtonOutlet;
@property (nonatomic, readwrite, weak) IBOutlet NSMatrix *savePanelAccessoryFileFormatMatrixOutlet;
@property (nonatomic, readwrite, weak) IBOutlet NSObjectController *savePanelProxy;

@property (nonatomic, readwrite, weak) PlainTextDocument *document;
@property (nonatomic, readwrite, weak) NSSavePanel *savePanel;
@property (nonatomic, readwrite, assign) NSSaveOperationType *saveOperation;

@property (nonatomic, readonly) NSArray *writableDocumentTypes;

+ (BOOL)prepareSavePanel:(NSSavePanel *)savePanel withSaveOperation:(NSSaveOperationType)saveOperation forDocument:(NSDocument *)document;

@end
