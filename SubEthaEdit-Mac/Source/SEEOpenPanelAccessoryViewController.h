//
//  SEEOpenPanelAccessoryViewController.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 16.01.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EncodingPopUpButton, DocumentModePopUpButton;

@interface SEEOpenPanelAccessoryViewController : NSViewController

@property (nonatomic, readwrite, weak) NSOpenPanel *openPanel;

@property (nonatomic, weak) IBOutlet NSButton *goIntoBundlesCheckboxOutlet;
@property (nonatomic, weak) IBOutlet NSButton *showHiddenFilesCheckboxOutlet;
@property (nonatomic, weak) IBOutlet EncodingPopUpButton *encodingPopUpButtonOutlet;
@property (nonatomic, weak) IBOutlet DocumentModePopUpButton *modePopUpButtonOutlet;

+ (instancetype)openPanelAccessoryControllerForOpenPanel:(NSOpenPanel *)inOpenPanel;

- (IBAction)goIntoBundles:(id)sender;
- (IBAction)showHiddenFiles:(id)sender;

@end
