//  SEEFindAndReplaceViewController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 24.02.14.

#import <Cocoa/Cocoa.h>
@class SEEFindAndReplaceViewController;
#import "PlainTextWindowControllerTabContext.h"

@interface SEEFindAndReplaceViewController : NSViewController <NSMenuDelegate, NSTextFieldDelegate>

@property (nonatomic, weak) PlainTextWindowControllerTabContext *plainTextWindowControllerTabContext;

@property (nonatomic,strong) IBOutlet NSTextField *feedbackTextField;
@property (nonatomic,strong) IBOutlet NSTextField *findTextField;
@property (nonatomic,strong) IBOutlet NSTextField *replaceTextField;
@property (nonatomic,strong) IBOutlet NSSegmentedControl *findPreviousNextSegmentedControl;

@property (nonatomic,strong) IBOutlet NSButton *findAllButton;
@property (nonatomic,strong) IBOutlet NSButton *replaceButton;
@property (nonatomic,strong) IBOutlet NSButton *replaceAllButton;
@property (nonatomic,readonly) NSObjectController *findAndReplaceStateObjectController;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *findAllWidthConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *replaceAllWidthConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *mainViewHeightConstraint;

- (IBAction)findAndReplaceAction:(id)sender;
- (IBAction)dismissAction:(id)sender;

- (IBAction)findPreviousNextSegmentedControlAction:(id)sender;

- (void)updateSearchOptionsButton;

- (void)setEnabled:(BOOL)isEnabled;

@end
