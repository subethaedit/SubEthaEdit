//
//  AppController.h
//  SubEthaHighlighter
//
//  Created by Dominik Wagner on Tue Jan 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern int const kNoneModeMenuItemTag;

@interface AppController : NSObject {

}

+ (AppController *)sharedInstance;
- (void)setupSyntaxColoringSubmenu;
- (void)setupTestsSubmenu;

@end
