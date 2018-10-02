//
//  NSObject+TCMArcLifecycleAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 26.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import "NSObject+TCMArcLifecycleAdditions.h"

#import <objc/objc-runtime.h>

NSString * const kTCMARCLifeCycleContextObjectKey = @"__TCM_contextObjectKey";

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif


@implementation NSObject (TCMArcLifecycleAdditions)

static const void *TCMAssociatedMutableDictionaryAssocKey = &TCMAssociatedMutableDictionaryAssocKey;
- (NSMutableDictionary *)TCM_associatedMutableDictionary {
	NSMutableDictionary *result = objc_getAssociatedObject(self, TCMAssociatedMutableDictionaryAssocKey);
	if (!result) {
		result = [NSMutableDictionary new];
		objc_setAssociatedObject(self, TCMAssociatedMutableDictionaryAssocKey, result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return result;
}

- (void)TCM_setAssociatedValue:(id)anObject forKey:(NSString *)aKey {
	NSAssert(aKey != nil, @"Key cannot be nil for TCM_setObject:forKey:.");
	NSMutableDictionary *associatedDictionary = [self TCM_associatedMutableDictionary];
	if (anObject) {
		associatedDictionary[aKey] = anObject;
	} else {
		[associatedDictionary removeObjectForKey:aKey];
	}
}

- (id)TCM_associatedValueForKey:(NSString *)aKey {
	id result = [self TCM_associatedMutableDictionary][aKey];
	return result;
}

- (void)TCM_setContextObject:(id)anObject {
	[self TCM_setAssociatedValue:anObject forKey:kTCMARCLifeCycleContextObjectKey];
}

- (id)TCM_contextObject {
	id result = [self TCM_associatedValueForKey:kTCMARCLifeCycleContextObjectKey];
	return result;
}


@end
