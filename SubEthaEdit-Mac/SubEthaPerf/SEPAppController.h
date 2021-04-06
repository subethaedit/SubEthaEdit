//
//  SEPAppController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 09.04.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TCMMMUserManager : NSObject {
}
+ (NSString *)myUserID;
@end

@interface SEPAppController : NSObject {
	IBOutlet NSTextView *ibResultsTextView;
	IBOutlet NSProgressIndicator *ibProgressIndicator;

	BOOL testNSTextStorage;
	BOOL testFoldableTextStorage;
	BOOL testFoldableTextStorageOneFolding;
	BOOL testFoldableTextStorageEveryOtherLineFolding;
	int numberOfRepeats;
	NSFileHandle *logFileHandle;
	NSMutableDictionary *throughputDictionary;
}

@property int numberOfRepeats;
@property BOOL testNSTextStorage;
@property BOOL testFoldableTextStorage;
@property BOOL testFoldableTextStorageOneFolding;
@property BOOL testFoldableTextStorageEveryOtherLineFolding;

- (IBAction)runTests:(id)aSender;
- (IBAction)setReference:(id)aSender;

@end
