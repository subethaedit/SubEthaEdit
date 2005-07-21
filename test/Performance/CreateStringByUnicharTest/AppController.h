//
//  AppController.h
//  CreateStringByUnicharTest
//
//  Created by Dominik Wagner on 21.07.05.
//  Copyright 2005 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppController : NSObject {
    IBOutlet NSTextView *O_outputTextView;
    IBOutlet NSTextField *O_numberOfStringsTextField;
}

- (IBAction)testIt:(id)aSender;

@end
