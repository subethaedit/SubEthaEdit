//  NSRangeTCMAdditions.h
//  TCMFoundation
//
//  Created by Dominik Wagner on Thu Mar 31 2005.

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

FOUNDATION_STATIC_INLINE NSRange RangeConfinedToRange(NSRange aRange, NSRange aConfiningRange) {
    // we confine aRange to aConfiningRange. if aRange lies left of aConfiningRange it is set to
    // aConfiningRange.location,0 - if it lies right of aConfiningRange it is set to NSMaXRange(aConfiningRange,0)
    if (aRange.location < aConfiningRange.location) {
        if (NSMaxRange(aRange) < aConfiningRange.location) {
            return NSMakeRange(aConfiningRange.location,0);
        } else {
            aRange.length -= aConfiningRange.location - aRange.location;
            aRange.location = aConfiningRange.location;
        }
    }
    if (NSMaxRange(aRange)>NSMaxRange(aConfiningRange)) {
        if (NSMaxRange(aConfiningRange)<=aRange.location) {
            return NSMakeRange(NSMaxRange(aConfiningRange),0);
        } else {
            aRange.length = NSMaxRange(aConfiningRange)-aRange.location;
        }
    }
    return aRange;
}

