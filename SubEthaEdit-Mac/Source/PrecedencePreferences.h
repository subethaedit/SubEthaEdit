//  PrecedencePreferences.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 22.09.07.

#import <Cocoa/Cocoa.h>
#import "TCMPreferenceModule.h"


@interface PrecedencePreferences : TCMPreferenceModule <NSTableViewDelegate> 

@property (nonatomic, strong) IBOutlet NSButton *plusButton;

- (IBAction)addUserRule:(id)sender;
- (IBAction)removeUserRule:(id)sender;

@end
