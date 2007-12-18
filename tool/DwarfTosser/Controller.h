//
//  Controller.h
//  DwarfTosser
//
//  Created by Martin Pittenauer on 18.12.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Controller : NSObject {
	IBOutlet NSTextView * o_textView;
	IBOutlet NSTextField * o_statusText;
}

- (IBAction) resolveSymbols:(id)sender;

@end
