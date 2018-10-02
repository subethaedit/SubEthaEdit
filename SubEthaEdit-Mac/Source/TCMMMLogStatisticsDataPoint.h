//
//  TCMMMLogStatisticsDataPoint.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 24.09.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TCMMMLogStatisticsDataPoint : NSObject {
    unsigned long operationCount;
    unsigned long deletedCharacters;
    unsigned long insertedCharacters;
    unsigned long selectedCharacters;
}
- (id)initWithDataObject:(id)anObject;
- (unsigned long)operationCount;
- (unsigned long)deletedCharacters;
- (unsigned long)insertedCharacters;
- (unsigned long)selectedCharacters;
@end
