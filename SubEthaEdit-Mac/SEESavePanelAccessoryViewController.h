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

// Outlets for normal save panel
@property (nonatomic, readwrite, weak) IBOutlet NSView *savePanelAccessoryOutlet; // equal to self.view
@property (nonatomic, readwrite, weak) IBOutlet NSMatrix *savePanelAccessoryFileFormatMatrixOutlet;

// Outlets for the saveTo panel
@property (nonatomic, readwrite, weak) IBOutlet NSView *saveToPanelAccessoryOutlet;
@property (nonatomic, readwrite, weak) IBOutlet EncodingPopUpButton *encodingPopUpButtonOutlet;
@property (nonatomic, readwrite, weak) IBOutlet NSMatrix *saveToPanelAccessoryFileFormatMatrixOutlet;

// Outlets for both
@property (nonatomic, readwrite, strong) IBOutlet NSObjectController *savePanelProxy;

@property (nonatomic, readwrite, weak) PlainTextDocument *document;
@property (nonatomic, readwrite, weak) NSSavePanel *savePanel;
@property (nonatomic, readwrite, assign) NSSaveOperationType saveOperation;

+ (instancetype)prepareSavePanel:(NSSavePanel *)savePanel withSaveOperation:(NSSaveOperationType)saveOperation forDocument:(NSDocument *)document;

@end
