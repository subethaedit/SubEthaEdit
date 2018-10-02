//  SEEConnectionAddingWindowController.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 28.02.14.

#import <Cocoa/Cocoa.h>

@interface SEEConnectionAddingWindowController : NSWindowController
@property (nonatomic) NSString *addressString;

@property (nonatomic, strong) IBOutlet NSTextField *addressLabel;
@property (nonatomic, strong) IBOutlet NSButton *cancelButton;
@property (nonatomic, strong) IBOutlet NSButton *connectButton;
@end
