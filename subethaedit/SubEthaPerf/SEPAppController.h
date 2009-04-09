//
//  SEPAppController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 09.04.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SEPAppController : NSObject {
	IBOutlet NSTextView *ibResultsTextView;

}

- (IBAction)runTests:(id)aSender;

@end
