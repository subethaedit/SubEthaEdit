//
//  SEEPlainTextEditorTopBarViewController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 07.04.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class PlainTextEditor;
#import "PopUpButton.h"
#import "PlainTextEditor.h"

@interface SEEPlainTextEditorTopBarViewController : NSViewController
@property (nonatomic, weak) PlainTextEditor *editor;

@property (nonatomic, strong) IBOutlet PopUpButton *symbolPopUpButton;


- (void)adjustLayout; // temporary

- (void)updateForSelectionDidChange;

- (instancetype)initWithPlainTextEditor:(PlainTextEditor *)anEditor;
- (IBAction)positionButtonAction:(id)sender;
- (IBAction)splitToggleButtonAction:(id)sender;
@end
