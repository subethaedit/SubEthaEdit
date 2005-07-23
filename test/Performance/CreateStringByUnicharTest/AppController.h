//
//  AppController.h
//  CreateStringByUnicharTest
//
//  Created by Dominik Wagner on 21.07.05.
//  Copyright 2005 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TestView : NSView {
    BOOL I_shouldDraw;
    NSMutableDictionary *I_attributes;
    NSTextStorage *I_textStorage;
    NSLayoutManager *I_layoutManager;
    NSTextContainer *I_textContainer;
}

- (IBAction)testIt:(id)aSender;

@end

@interface AppController : NSObject {
    IBOutlet NSTextView *O_outputTextView;
    IBOutlet NSTextField *O_numberOfStringsTextField;
    IBOutlet TestView *O_testView;
}

- (IBAction)testIt:(id)aSender;

@end

