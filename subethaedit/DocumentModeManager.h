//
//  DocumentModeManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DocumentModeManager : NSObject {
    NSMutableDictionary *I_modeBundles;
    NSMutableDictionary *I_modes;
}

+ (DocumentModeManager *)sharedInstance;

@end
