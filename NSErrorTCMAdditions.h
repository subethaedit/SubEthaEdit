//
//  NSErrorTCMAdditions.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 02.09.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSError (NSErrorTCMAdditions) 

-(BOOL)TCM_relatesToErrorCode:(int)aCode inDomain:(NSString*)aDomain;
-(BOOL)TCM_matchesCode:(int)aCode inDomain:(NSString*)aDomain;

@end
