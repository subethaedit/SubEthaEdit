//
//  NSRangeTCMAdditions.h
//  TCMFoundation
//
//  Created by Dominik Wagner on Thu Mar 31 2005.
//  Copyright (c) 2005 TheCodingMonkeys. All rights reserved.
//

FOUNDATION_STATIC_INLINE BOOL DisjointRanges(NSRange range1, NSRange range2) {
    return  !(range1.location < NSMaxRange(range2)
              && NSMaxRange(range1) > range2.location);
}

FOUNDATION_STATIC_INLINE BOOL TouchingRanges(NSRange range1, NSRange range2) {
    return (range1.location <= NSMaxRange(range2)
            && NSMaxRange(range1) >= range2.location);
}

FOUNDATION_STATIC_INLINE int EndCharacterIndex(NSRange aRange) {
    if (aRange.length==0) return aRange.location;
    return NSMaxRange(aRange)-1;
}
