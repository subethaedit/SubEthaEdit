//
//  SEEPlainTextEditorTopBarViewController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 07.04.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import "SEEPlainTextEditorTopBarViewController.h"
#import "PopUpButton.h"
#import "PlainTextDocument.h"
#import "DocumentMode.h"

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif


@interface SEEPlainTextEditorTopBarViewController ()
@property (nonatomic, strong) IBOutlet NSTextField *writtenByTextField;
@property (nonatomic, strong) IBOutlet NSTextField *positionTextField;
@property (nonatomic, strong) IBOutlet NSButton *splitButton;
@property (nonatomic, strong) IBOutlet NSImageView *terminalIconImageView;
@end

@implementation SEEPlainTextEditorTopBarViewController

- (instancetype)initWithPlainTextEditor:(PlainTextEditor *)anEditor {
	self = [self initWithNibName:nil bundle:nil];
	if (self) {
		self.editor = anEditor;
	}
	return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:@"SEEPlainTextEditorTopBarViewController" bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)dealloc {
	self.symbolPopUpButton.delegate = nil;
}

- (void)loadView {
	[super loadView];
	self.view.layer.backgroundColor = [[NSColor colorWithCalibratedWhite:0.5 alpha:0.5] CGColor];
	
	[self.symbolPopUpButton setDelegate:self.editor];
}

- (void)adjustLayout {
	
}

- (IBAction)positionButtonAction:(id)sender {
}

- (IBAction)splitToggleButtonAction:(id)sender {
}

- (void)updateSelectedSymbolInPopUp:(PopUpButton *)aPopUp {
    PlainTextDocument *document = self.editor.document;
	
    if ([[document documentMode] hasSymbols])
    {
        int symbolTag = [document selectedSymbolForRange:[document.textStorage fullRangeForFoldedRange:[self.editor.textView selectedRange]]];
		
        if (symbolTag == -1)
        {
            [aPopUp selectItemAtIndex:0];
        }
        else
        {
            [aPopUp selectItem:[aPopUp.menu itemWithTag:symbolTag]];
        }
    }
}

- (void)updateForSelectionDidChange {
	NSRange selection = [self.editor.textView selectedRange];
	FoldableTextStorage *textStorage = (FoldableTextStorage *)self.editor.textView.textStorage;
	NSString *positionString = [textStorage positionStringForRange:selection];

	if (selection.location < [textStorage length]) {
		id blockAttribute = [textStorage attribute:BlockeditAttributeName
										   atIndex:selection.location
									effectiveRange:nil];
		
		if (blockAttribute) positionString = [positionString stringByAppendingFormat:@" %@", NSLocalizedString(@"[Blockediting]", nil)];
	}

	[self.positionTextField setStringValue:positionString];
	
	
	NSString *writtenByValue = @"";
	
	NSString *followUserID = [self.editor followUserID];
	
	if (followUserID) {
		NSString *userName = [[[TCMMMUserManager sharedInstance] userForUserID:followUserID] name];
		
		if (userName) {
			writtenByValue = [NSString stringWithFormat:NSLocalizedString(@"Following %@", "Status bar text when following"), userName];
		}
	} else {
		if (selection.location < textStorage.length) {
			NSRange range;
			NSString *userId = [textStorage attribute:WrittenByUserIDAttributeName
											  atIndex:selection.location
								longestEffectiveRange:&range
											  inRange:selection];
			
			if (!userId &&
				selection.length > range.length) {
				
				userId = [textStorage attribute:WrittenByUserIDAttributeName
										atIndex:NSMaxRange(range)
						  longestEffectiveRange:&range
										inRange:selection];
			}
			
			if (userId) {
				NSString *userName = nil;
				
				if ([userId isEqualToString:[TCMMMUserManager myUserID]]) {
					userName = NSLocalizedString(@"me", nil);
				} else {
					userName = [[[TCMMMUserManager sharedInstance] userForUserID:userId] name];
					if (!userName) userName = @"";
				}
				
				if (selection.length > range.length) {
					writtenByValue = [NSMutableString stringWithFormat:NSLocalizedString(@"Written by %@ et al", nil), userName];
				} else {
					writtenByValue = [NSMutableString stringWithFormat:NSLocalizedString(@"Written by %@", nil), userName];
				}
			}
		}
	}
	
	[self.writtenByTextField setStringValue:writtenByValue];

	[self updateSelectedSymbolInPopUp:self.symbolPopUpButton];
	
	[self adjustLayout];
}


@end
