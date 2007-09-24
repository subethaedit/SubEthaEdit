//
//  TCMMMLogStatisticsDataPoint.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 24.09.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMLogStatisticsDataPoint.h"


@implementation TCMMMLogStatisticsDataPoint

- (id)initWithDataObject:(id)anObject {
    if ((self = [super init])) {
        operationCount = [anObject operationCount];
        deletedCharacters = [anObject deletedCharacters];
        insertedCharacters = [anObject insertedCharacters];
        selectedCharacters = [anObject selectedCharacters];
    }
    return self;
}

- (unsigned long)operationCount {
    return operationCount;
}
- (unsigned long)deletedCharacters {
    return deletedCharacters;
}
- (unsigned long)insertedCharacters {
    return insertedCharacters;
}
- (unsigned long)selectedCharacters {
    return selectedCharacters;
}

@end
