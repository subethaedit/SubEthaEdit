//
//  AppController.h
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


#define kKAHL 'KAHL'
#define kMOD 'MOD '


@interface AppController : NSObject {

}

- (IBAction)undo:(id)aSender;
- (IBAction)redo:(id)aSender;

- (IBAction)purchaseSubEthaEdit:(id)sender;
- (IBAction)enterSerialNumber:(id)sender;

- (IBAction)showLicense:(id)sender;
- (IBAction)showAcknowledgements:(id)sender;
- (IBAction)showRegExHelp:(id)sender;
- (IBAction)visitWebsite:(id)sender;
- (IBAction)reportBug:(id)sender;

@end
