//
//  DocumentMode.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DocumentMode : NSObject {
    NSBundle *I_bundle;
}

- (id)initWithBundle:(NSBundle *)aBundle;

- (NSBundle *)bundle;

@end
