//
//  SEESavePanelAccessoryViewController.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.10.13.
//  Copyright (c) 2013 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EncodingPopUpButton;

@interface SEESavePanelAccessoryViewController : NSViewController

@property (nonatomic, readwrite, weak) IBOutlet NSButton *goIntoBundlesCheckboxOutlet;
@property (nonatomic, readwrite, weak) IBOutlet NSButton *showHiddenFilesCheckboxOutlet;
@property (nonatomic, readwrite, weak) IBOutlet EncodingPopUpButton *encodingPopUpButtonOutlet;
@property (nonatomic, readwrite, weak) IBOutlet NSMatrix *savePanelAccessoryFileFormatMatrixOutlet;
@property (nonatomic, readwrite, weak) IBOutlet NSObjectController *savePanelProxy;

@property (nonatomic, readwrite, weak) NSSavePanel *savePanel;

@end
