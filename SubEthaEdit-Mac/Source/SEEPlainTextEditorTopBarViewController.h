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
@property (nonatomic, getter=isVisible) BOOL visible;

@property (nonatomic, getter=isSplitButtonVisible) BOOL splitButtonVisible;
@property (nonatomic) BOOL splitButtonShowsClose;
@property (nonatomic, getter=isWaitPipeImageVisible) BOOL waitPipeImageVisible;

- (void)adjustLayout; // temporary

- (void)updateColorsForIsDarkBackground:(BOOL)isDark;
- (void)updateForSelectionDidChange;
- (void)updateSymbolPopUpContent;

- (instancetype)initWithPlainTextEditor:(PlainTextEditor *)anEditor;
- (IBAction)positionButtonAction:(id)sender;
- (IBAction)splitToggleButtonAction:(id)sender;
- (IBAction)toggleDocumentInfoLabel:(id)sender;
- (IBAction)keyboardActivateSymbolPopUp;
@end
