//
//  DebugController.h
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Apr 23 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#ifndef TCM_NO_DEBUG


#import <Foundation/Foundation.h>


@interface DebugController : NSObject
{
}

+ (DebugController *)sharedInstance;

- (void)enableDebugMenu:(BOOL)flag;

@end


#endif