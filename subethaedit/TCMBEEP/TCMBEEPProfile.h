//
//  TCMBEEPProfile.h
//  TCMBEEP
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TCMBEEPMessage;

@protocol TCMBEEPProfile

- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage;

@end