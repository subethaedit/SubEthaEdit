//
//  Functions.m
//  SubEthaEdit
//
//  Created by Martin Ott on Thu Mar 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "Functions.h"

BOOL DisjointRanges(NSRange range1, NSRange range2) {
    if (range1.location < NSMaxRange(range2)
        && NSMaxRange(range1) > range2.location) {
        return NO;
    } else {
        return YES;
    }
}
