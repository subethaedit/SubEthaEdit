//  NSDictionaryTCMAdditions.m
//  TCMFoundation
//
//  Created by Martin Ott on Wed Feb 18 2004.

#import "NSDictionaryTCMAdditions.h"

static Boolean
CaseInsensitiveDictionaryKeyEqualCallBack(const void *value1, const void *value2)
{
    const CFTypeID stringID = CFStringGetTypeID();

    if (CFGetTypeID(value1) == stringID && CFGetTypeID(value2) == stringID) {
    
        if (CFStringCompare((CFStringRef)value1, (CFStringRef)value2, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
            return true;
        }
        return false;
    }
    else {
        return kCFTypeDictionaryKeyCallBacks.equal(value1, value2);
    }
} 


static CFHashCode
CaseInsensitiveDictionaryKeyHashCallBack(const void *value)
{
    const CFTypeID stringID = CFStringGetTypeID();
    
    if (CFGetTypeID(value) == stringID) {
    
        CFIndex length = CFStringGetLength(value);                
        unsigned char * pointer = malloc(length + 1);
        unsigned char * cStr = pointer;
        int index;
    
        assert(cStr != NULL);
    
        CFStringGetCString(value, (char *)cStr, length + 1, kCFStringEncodingASCII);
    
        for (index = 0; index < length; index++) {
            cStr[index] = tolower(cStr[index]);
        }
    
        CFHashCode result = 0;
        if (length <= 4) {	// All chars
            unsigned cnt = (unsigned)length;
            while (cnt--) result += (result << 8) + *cStr++;
        } else {		// First and last 2 chars
            result += (result << 8) + cStr[0];
            result += (result << 8) + cStr[1];
            result += (result << 8) + cStr[length-2];
            result += (result << 8) + cStr[length-1];
        }
        result += (result << (length & 31));
        free(pointer);
        return result;
    }
    else {
        return kCFTypeDictionaryKeyCallBacks.hash(value);
    }
}


@implementation NSDictionary (NSDictionaryTCMAdditions)

- (id)objectForLong:(long)aLong
{
    return [self objectForKey:[NSNumber numberWithLong:aLong]];
}

@end


@implementation NSMutableDictionary (NSDictionaryTCMAdditions)

+ (NSMutableDictionary *)caseInsensitiveDictionary {
    CFMutableDictionaryRef insensitiveDictionary;
    const CFDictionaryKeyCallBacks keyCallBacks = 
                    { kCFTypeDictionaryKeyCallBacks.version, kCFTypeDictionaryKeyCallBacks.retain,
					  kCFTypeDictionaryKeyCallBacks.release, kCFTypeDictionaryKeyCallBacks.copyDescription,
					  CaseInsensitiveDictionaryKeyEqualCallBack, CaseInsensitiveDictionaryKeyHashCallBack };

    // We create our own equal and hash callback functions because TXT record key names should be case insensitive.
    insensitiveDictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &keyCallBacks, &kCFTypeDictionaryValueCallBacks);
    NSMutableDictionary *result = CFBridgingRelease(insensitiveDictionary);
    return result;
}


- (void)setObject:(id)anObject forLong:(long)aLong {
    [self setObject:anObject forKey:[NSNumber numberWithLong:aLong]];
}

- (void)removeObjectForLong:(long)aLong {
    [self removeObjectForKey:[NSNumber numberWithLong:aLong]];
}

@end

