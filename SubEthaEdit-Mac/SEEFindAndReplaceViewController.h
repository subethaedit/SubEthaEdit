//
//  SEEFindAndReplaceViewController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 24.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SEEFindAndReplaceViewController;

@protocol SEEFindAndReplaceViewControllerDelegate
@property (nonatomic, readonly) NSTextView *textView;
- (void)findAndReplaceViewControllerDidPressDismiss:(SEEFindAndReplaceViewController *)aViewController;
@end

@interface SEEFindAndReplaceViewController : NSViewController

@property (nonatomic, weak) id <SEEFindAndReplaceViewControllerDelegate> delegate;

@property (nonatomic,strong) IBOutlet NSTextField *feedbackTextField;
@property (nonatomic,strong) IBOutlet NSTextField *findTextField;
@property (nonatomic,strong) IBOutlet NSTextField *replaceTextField;
@property (nonatomic,strong) IBOutlet NSButton *findPreviousButton;
@property (nonatomic,strong) IBOutlet NSButton *findNextButton;
@property (nonatomic,strong) IBOutlet NSButton *replaceButton;
@property (nonatomic,strong) IBOutlet NSButton *replaceAllButton;
@property (nonatomic,strong) IBOutlet NSButton *searchOptionsButton;
@property (nonatomic,readonly) NSObjectController *findAndReplaceStateObjectController;

- (IBAction)findAndReplaceAction:(id)sender;
- (IBAction)dismissAction:(id)sender;
- (IBAction)searchOptionsDropdownAction:(id)sender;


- (void)updateSearchOptionsButton;
@end
