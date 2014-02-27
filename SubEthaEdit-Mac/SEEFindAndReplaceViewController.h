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

@property (nonatomic,strong) IBOutlet NSTextField *findTextField;
@property (nonatomic,strong) IBOutlet NSTextField *replaceTextField;
@property (nonatomic,strong) IBOutlet NSButton *findPreviousButton;
@property (nonatomic,strong) IBOutlet NSButton *findNextButton;
@property (nonatomic,strong) IBOutlet NSButton *replaceButton;
@property (nonatomic,strong) IBOutlet NSButton *replaceAllButton;

- (IBAction)findTextFieldAction:(id)sender;
- (IBAction)findPreviousAction:(id)sender;
- (IBAction)findNextAction:(id)sender;
- (IBAction)replaceAction:(id)sender;
- (IBAction)replaceAllAction:(id)sender;
- (IBAction)dismissAction:(id)sender;
@end
