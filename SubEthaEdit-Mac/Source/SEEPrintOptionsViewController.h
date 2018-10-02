//  SEEPrintOptionsViewController.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 17.10.13.

#import <Cocoa/Cocoa.h>

@class PlainTextDocument, FontForwardingTextField;

@interface SEEPrintOptionsViewController : NSViewController <NSPrintPanelAccessorizing>

@property (nonatomic, readwrite, weak) PlainTextDocument *document;
@property (nonatomic, readwrite, weak) IBOutlet NSObjectController *printOptionControllerOutlet;
@property (nonatomic, readwrite, weak) IBOutlet FontForwardingTextField *printOptionTextFieldOutlet;
    
- (IBAction)changeFontViaPanel:(id)sender;

@end
