// Asterism.m
//
// Amalgamation generated from:
// 44ed990 (Fix typo, Sat Sep 26 13:59:57 2020 +0200)

#import "Asterism.h"

#pragma mark - ASTAll.m

BOOL __ASTAll_NSDictionary(NSDictionary *dict, BOOL(^block)(id obj)) {
    return ASTAll(dict.allValues, block);
}

BOOL __ASTAll_NSFastEnumeration(id<NSFastEnumeration> collection, BOOL(^block)(id)) {
    NSCParameterAssert(block != nil);

    BOOL didTest = NO;

    for (id obj in collection) {
        if (!block(obj)) return NO;

        didTest = YES;
    }

    return didTest;
}

#pragma mark - ASTAny.m

BOOL __ASTAny_NSDictionary(NSDictionary *dict, BOOL(^block)(id obj)) {
    return ASTAny(dict.allValues, block);
}

BOOL __ASTAny_NSFastEnumeration(id<NSFastEnumeration> collection, BOOL(^block)(id)) {
    NSCParameterAssert(block != nil);

    for (id obj in collection) {
        if (block(obj)) return YES;
    }

    return NO;
}

#pragma mark - ASTDefaults.m

NSDictionary *__ASTDefaults_NSDictionary(NSDictionary *dict, NSDictionary *defaults) {
    if (dict == nil) return defaults;
    if (defaults == nil) return dict;

    NSMutableDictionary *result = [dict mutableCopy];

    [defaults enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (result[key] == nil) result[key] = obj;
    }];

    return result;
}

#pragma mark - ASTDifference.m

NSArray *__ASTDifference_NSArray(NSArray *array, NSArray *other) {
    if (array == nil) return nil;
    if (other == nil) return array;

    NSMutableArray *result = [array mutableCopy];

    [result removeObjectsInArray:other];

    return [result copy];
}

NSSet *__ASTDifference_NSSet(NSSet *set, NSSet *other) {
    if (set == nil) return nil;
    if (other == nil) return set;

    NSMutableSet *result = [set mutableCopy];

    [result minusSet:other];

    return [result copy];
}

NSOrderedSet *__ASTDifference_NSOrderedSet(NSOrderedSet *set, NSOrderedSet *other) {
    if (set == nil) return nil;
    if (other == nil) return set;

    NSMutableOrderedSet *result = [set mutableCopy];

    [result minusOrderedSet:other];

    return [result copy];
}

#pragma mark - ASTEach.m

void __ASTEach_NSArray(NSArray *array, void(^iterator)(id)) {
    NSCParameterAssert(iterator != nil);

    ASTEach((id<NSFastEnumeration>)array, iterator);
}

void __ASTEach_NSArray_withIndex(NSArray *array, void(^iterator)(id, NSUInteger)) {
    NSCParameterAssert(iterator != nil);

    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        iterator(obj, idx);
    }];
}

void __ASTEach_NSDictionary(NSDictionary *dict, void(^iterator)(id obj)) {
    NSCParameterAssert(iterator != nil);

    ASTEach(dict, ^(id key, id obj) {
        iterator(obj);
    });
}

void __ASTEach_NSDictionary_keysAndValues(NSDictionary *dict, void(^iterator)(id key, id obj)) {
    NSCParameterAssert(iterator != nil);

    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        iterator(key, obj);
    }];
}

void __ASTEach_NSOrderedSet_withIndex(NSOrderedSet *set, void(^iterator)(id, NSUInteger)) {
    NSCParameterAssert(iterator != nil);

    [set enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        iterator(obj, idx);
    }];
}

void __ASTEach_NSFastEnumeration(id<NSFastEnumeration> enumerable, void(^iterator)(id obj)) {
    NSCParameterAssert(iterator != nil);

    for (id obj in enumerable) {
        iterator(obj);
    }
}

void __ASTEach_NSFastEnumeration_withIndex(id<NSFastEnumeration> enumerable, void(^iterator)(id obj, NSUInteger idx)) {
    NSCParameterAssert(iterator != nil);

    NSUInteger idx = 0;

    for (id obj in enumerable) {
        iterator(obj, idx);
        idx++;
    }
}

#pragma mark - ASTEmpty.m

BOOL __ASTEmpty_NSArray(NSArray *array) {
    return array.count == 0;
}

BOOL __ASTEmpty_NSDictionary(NSDictionary *dictionary) {
    return dictionary.count == 0;
}

BOOL __ASTEmpty_NSSet(NSSet *set) {
    return set.count == 0;
}

BOOL __ASTEmpty_NSOrderedSet(NSOrderedSet *set) {
    return set.count == 0;
}

BOOL __ASTEmpty_NSFastEnumeration(id<NSFastEnumeration> collection) {
    for (__attribute__((unused)) id _ in collection) return NO;

    return YES;
}

#pragma mark - ASTExtend.m

NSDictionary *__ASTExtend_NSDictionary(NSDictionary *dict, NSDictionary *source) {
    if (dict == nil) return source;
    if (source == nil) return dict;

    NSMutableDictionary *result = [dict mutableCopy];

    [source enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        result[key] = obj;
    }];

    return result;
}

#pragma mark - ASTFilter.m

NSArray *__ASTFilter_NSArray(NSArray *array, BOOL(^block)(id)) {
    NSCParameterAssert(block != nil);

    NSIndexSet *indexes = [array indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return block(obj);
    }];

    return [array objectsAtIndexes:indexes];
}

NSArray *__ASTFilter_NSArray_withIndex(NSArray *array, BOOL(^block)(id, NSUInteger)) {
    NSCParameterAssert(block != nil);

    NSIndexSet *indexes = [array indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return block(obj, idx);
    }];

    return [array objectsAtIndexes:indexes];
}

NSDictionary *__ASTFilter_NSDictionary(NSDictionary *dict, BOOL(^block)(id)) {
    NSCParameterAssert(block != nil);

    NSSet *keys = [dict keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        return block(obj);
    }];

    return [dict dictionaryWithValuesForKeys:keys.allObjects];
}

NSDictionary *__ASTFilter_NSDictionary_keysAndValues(NSDictionary *dict, BOOL(^block)(id, id)) {
    NSCParameterAssert(block != nil);

    NSSet *keys = [dict keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        return block(key, obj);
    }];

    return [dict dictionaryWithValuesForKeys:keys.allObjects];
}

NSSet *__ASTFilter_NSSet(NSSet *set, BOOL(^block)(id)) {
    NSCParameterAssert(block != nil);

    return [set objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return block(obj);
    }];
}

NSOrderedSet *__ASTFilter_NSOrderedSet(NSOrderedSet *set, BOOL(^block)(id)) {
    NSCParameterAssert(block != nil);

    NSIndexSet *indexes = [set indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return block(obj);
    }];

    return [NSOrderedSet orderedSetWithArray:[set objectsAtIndexes:indexes]];
}

NSOrderedSet *__ASTFilter_NSOrderedSet_withIndex(NSOrderedSet *set, BOOL(^block)(id, NSUInteger)) {
    NSCParameterAssert(block != nil);

    NSIndexSet *indexes = [set indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return block(obj, idx);
    }];

    return [NSOrderedSet orderedSetWithArray:[set objectsAtIndexes:indexes]];
}

#pragma mark - ASTFind.m

id __ASTFind_NSArray(NSArray *array, BOOL(^block)(id)) {
    NSCParameterAssert(block != nil);

    if (array == nil) return nil;

    NSUInteger index = [array indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return block(obj);
    }];

    return index == NSNotFound ? nil : array[index];
}

id __ASTFind_NSArray_withIndex(NSArray *array, BOOL(^block)(id, NSUInteger)) {
    NSCParameterAssert(block != nil);

    if (array == nil) return nil;

    NSUInteger index = [array indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return block(obj, idx);
    }];

    return index == NSNotFound ? nil : array[index];
}

id __ASTFind_NSDictionary(NSDictionary *dict, BOOL(^block)(id)) {
    NSCParameterAssert(block != nil);

    for (id key in dict) {
        id value = dict[key];

        if (block(value)) return value;
    }

    return nil;
}

id __ASTFind_NSDictionary_keysAndValues(NSDictionary *dict, BOOL(^block)(id, id)) {
    NSCParameterAssert(block != nil);

    for (id key in dict) {
        id value = dict[key];

        if (block(key, value)) return value;
    }

    return nil;
}

id __ASTFind_NSFastEnumeration(id<NSFastEnumeration> collection, BOOL(^block)(id obj)) {
    NSCParameterAssert(block != nil);

    for (id obj in collection) {
        if (block(obj)) return obj;
    }

    return nil;
}

#pragma mark - ASTFlatten.m

NSArray *__ASTFlatten_NSArray(NSArray *array) {
    NSMutableArray *result = [NSMutableArray array];

    for (NSArray *element in array) {
        if ([element isKindOfClass:[NSArray class]]) {
            [result addObjectsFromArray:element];
        } else {
            [result addObject:element];
        }
    }

    return result;
}

#pragma mark - ASTGroupBy.m

NSDictionary *__ASTGroupBy_NSDictionary_block(NSDictionary *dict, id<NSCopying> (^block)(id obj)) {
    return ASTGroupBy(dict.allValues, block);
}

NSDictionary *__ASTGroupBy_NSDictionary_keyPath(NSDictionary *dict, NSString *keyPath) {
    return ASTGroupBy(dict.allValues, keyPath);
}

NSDictionary *__ASTGroupBy_NSFastEnumeration_block(id<NSFastEnumeration> collection, id<NSCopying> (^block)(id)) {
    NSCParameterAssert(block != nil);

    if (collection == nil) return nil;

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    for (id obj in collection) {
        id<NSCopying> key = block(obj);

        if (key == nil) continue;

        NSArray *group = dictionary[key] ?: @[];

        dictionary[key] = [group arrayByAddingObject:obj];
    }

    return dictionary;
}

NSDictionary *__ASTGroupBy_NSFastEnumeration_keyPath(id<NSFastEnumeration> collection, NSString *keyPath) {
    NSCParameterAssert(keyPath != nil);

    return ASTGroupBy(collection, ^(id obj) {
        return [obj valueForKeyPath:keyPath];
    });
}

#pragma mark - ASTHead.m

id __ASTHead_NSArray(NSArray *array) {
    return array.count > 0 ? array[0] : nil;
}

id __ASTHead_NSOrderedSet(NSOrderedSet *set) {
    return set.count > 0 ? set[0] : nil;
}

#pragma mark - ASTIndexBy.m

NSDictionary *__ASTIndexBy_NSDictionary_block(NSDictionary *dict, id<NSCopying> (^block)(id obj)) {
    return ASTIndexBy(dict.allValues, block);
}

NSDictionary *__ASTIndexBy_NSDictionary_keyPath(NSDictionary *dict, NSString *keyPath) {
    return ASTIndexBy(dict.allValues, keyPath);
}

NSDictionary *__ASTIndexBy_NSFastEnumeration_block(id<NSFastEnumeration> collection, id<NSCopying> (^block)(id)) {
    NSCParameterAssert(block != nil);

    if (collection == nil) return nil;

    return ASTReduce(collection, [NSMutableDictionary dictionary], ^(NSMutableDictionary *result, id obj) {
        id key = block(obj);

        if (key != nil) result[key] = obj;

        return result;
    });
}

NSDictionary *__ASTIndexBy_NSFastEnumeration_keyPath(id<NSFastEnumeration> collection, NSString *keyPath) {
    return ASTIndexBy(collection, ^(id obj) {
        return [obj valueForKeyPath:keyPath];
    });
}

#pragma mark - ASTIndexOf.m

NSUInteger __ASTIndexOf_NSArray(NSArray *array, id obj) {
    return [array indexOfObject:obj];
}

NSUInteger __ASTIndexOf_NSOrderedSet(NSOrderedSet *set, id obj) {
    return [set indexOfObject:obj];
}

NSUInteger __ASTIndexOf_NSFastEnumeration(id<NSFastEnumeration> collection, id obj) {
    if (collection == nil || obj == nil) return NSNotFound;

    NSUInteger index = 0;

    for (id other in collection) {
        if ([obj isEqual:other]) return index;

        index++;
    }

    return NSNotFound;
}

#pragma mark - ASTIntersection.m

NSArray *__ASTIntersection_NSArray(NSArray *array, NSArray *other) {
    if (array == nil) return other;
    if (other == nil) return array;

    NSMutableArray *result = [array mutableCopy];

    for (id obj in array) {
        if (![other containsObject:obj]) {
            [result removeObject:obj];
        }
    }

    return [result copy];
}

NSSet *__ASTIntersection_NSSet(NSSet *set, NSSet *other) {
    if (set == nil) return other;
    if (other == nil) return set;

    NSMutableSet *result = [set mutableCopy];
    [result intersectSet:other];

    return [result copy];
}

NSOrderedSet *__ASTIntersection_NSOrderedSet(NSOrderedSet *set, NSOrderedSet *other) {
    if (set == nil) return other;
    if (other == nil) return set;

    NSMutableOrderedSet *result = [set mutableCopy];
    [result intersectOrderedSet:other];

    return [result copy];
}

#pragma mark - ASTMap.m

#pragma mark - Arrays

NSArray *__ASTMap_NSArray(NSArray *array, id(^block)(id obj)) {
    NSCParameterAssert(block != nil);

    if (array == nil) return nil;

    return ASTMap(array, ^(id obj, NSUInteger _) {
        return block(obj);
    });
}

NSArray *__ASTMap_NSArray_withIndex(NSArray *array, id(^block)(id obj, NSUInteger idx)) {
    NSCParameterAssert(block != nil);

    if (array == nil) return nil;

    NSMutableArray *result = [NSMutableArray array];

    ASTEach(array, ^(id obj, NSUInteger idx) {
        id transformed = block(obj, idx);

        if (transformed != nil) {
            [result addObject:transformed];
        }
    });

    return result;
}

NSDictionary *__ASTMap_NSDictionary(NSDictionary *dict, id(^block)(id obj)) {
    NSCParameterAssert(block != nil);

    if (dict == nil) return nil;

    return ASTMap(dict, ^(id _, id obj) {
        return block(obj);
    });
}

NSDictionary *__ASTMap_NSDictionary_keysAndValues(NSDictionary *dict, id(^block)(id key, id obj)) {
    NSCParameterAssert(block != nil);

    if (dict == nil) return nil;

    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    ASTEach(dict, ^(id key, id obj) {
        id transformed = block(key, obj);

        if (transformed != nil) {
            result[key] = transformed;
        }
    });

    return result;
}

NSSet *__ASTMap_NSSet(NSSet *set, id(^block)(id obj)) {
    NSCParameterAssert(block != nil);

    if (set == nil) return nil;

    NSMutableSet *result = [NSMutableSet set];

    ASTEach(set, ^(id obj) {
        id transformed = block(obj);

        if (transformed != nil) {
            [result addObject:transformed];
        }
    });

    return result;
}

NSOrderedSet *__ASTMap_NSOrderedSet(NSOrderedSet *set, id(^block)(id obj)) {
    NSCParameterAssert(block != nil);

    if (set == nil) return nil;

    return ASTMap(set, ^(id obj, NSUInteger _) {
        return block(obj);
    });
}

NSOrderedSet *__ASTMap_NSOrderedSet_withIndex(NSOrderedSet *set, id(^block)(id obj, NSUInteger idx)) {
    NSCParameterAssert(block != nil);

    if (set == nil) return nil;

    NSMutableOrderedSet *result = [NSMutableOrderedSet orderedSet];

    ASTEach(set, ^(id obj, NSUInteger idx) {
        id transformed = block(obj, idx);

        if (transformed != nil) {
            [result addObject:transformed];
        }
    });

    return result;
}

NSArray *__ASTMap_NSFastEnumeration(id<NSFastEnumeration> collection, id(NS_NOESCAPE ^block)(id obj)) {
    NSCParameterAssert(block != nil);

    if (collection == nil) return nil;

    return ASTMap(collection, ^(id obj, NSUInteger _) {
        return block(obj);
    });
}

NSArray *__ASTMap_NSFastEnumeration_withIndex(id<NSFastEnumeration> collection, id(NS_NOESCAPE ^block)(id obj, NSUInteger idx)) {
    NSCParameterAssert(block != nil);

    if (collection == nil) return nil;

    NSMutableArray *result = [NSMutableArray array];

    ASTEach(collection, ^(id obj, NSUInteger idx) {
        id transformed = block(obj, idx);

        if (transformed != nil) {
            [result addObject:transformed];
        }
    });

    return result;
}

#pragma mark - ASTMinMax.m

#pragma mark - Helpers

static NSComparator const ASTMinMax_Compare = ^NSComparisonResult(id a, id b) {
    return [a compare:b];
};

#pragma mark - Min

id __ASTMin_NSDictionary(NSDictionary *dict) {
    return ASTMin(dict.allValues);
}

id __ASTMin_NSDictionary_comparator(NSDictionary *dict, NSComparator comparator) {
    return ASTMin(dict.allValues, comparator);
}

id __ASTMin_NSFastEnumeration(id<NSFastEnumeration> collection) {
    return ASTMin(collection, ASTMinMax_Compare);
}

id __ASTMin_NSFastEnumeration_comparator(id<NSFastEnumeration> collection, NSComparator comparator) {
    NSCParameterAssert(comparator != nil);

    return ASTReduce(collection, ^id(id a, id b) {
        return comparator(a, b) == NSOrderedAscending ? a : b;
    });
}

#pragma mark - Max

id __ASTMax_NSDictionary(NSDictionary *dict) {
    return ASTMax(dict.allValues);
}

id __ASTMax_NSDictionary_comparator(NSDictionary *dict, NSComparator comparator) {
    return ASTMax(dict.allValues, comparator);
}

id __ASTMax_NSFastEnumeration(id<NSFastEnumeration> collection) {
    return ASTMax(collection, ASTMinMax_Compare);
}

id __ASTMax_NSFastEnumeration_comparator(id<NSFastEnumeration> collection, NSComparator comparator) {
    NSCParameterAssert(comparator != nil);

    return ASTReduce(collection, ^id(id a, id b) {
        return comparator(a, b) == NSOrderedDescending ? a : b;
    });
}

#pragma mark - ASTNegate.m

BOOL (^__ASTNegate_id(BOOL(^block)(id)))(id) {
    return ^BOOL (id arg1){
        return !block(arg1);
    };
}

BOOL (^__ASTNegate_id_id(BOOL(^block)(id, id)))(id, id) {
    return ^BOOL (id arg1, id arg2){
        return !block(arg1, arg2);
    };
}

BOOL (^__ASTNegate_id_NSUInteger(BOOL(^block)(id, NSUInteger)))(id, NSUInteger) {
    return ^BOOL (id arg1, NSUInteger arg2){
        return !block(arg1, arg2);
    };
}

#pragma mark - ASTPick.m

NSDictionary *__ASTPick_NSDictionary(NSDictionary *dict, NSArray *keys) {
    return ASTFilter(dict, ^BOOL(id key, id obj) {
        return [keys containsObject:key];
    });
}

#pragma mark - ASTPluck.m

NSDictionary *__ASTPluck_NSDictionary(NSDictionary *dict, NSString *keyPath) {
    NSCParameterAssert(keyPath != nil);

    return ASTMap(dict, ^id(id obj) {
        return [obj valueForKeyPath:keyPath];
    });
}

NSArray *__ASTPluck_NSFastEnumeration(id<NSFastEnumeration> collection, NSString *keyPath) {
    NSCParameterAssert(keyPath != nil);

    if (collection == nil) return nil;

    NSMutableArray *result = [NSMutableArray array];

    for (id obj in collection) {
        id value = [obj valueForKeyPath:keyPath];

        if (value != nil) {
            [result addObject:value];
        }
    }

    return result;
}

#pragma mark - ASTReduce.m

id __ASTReduce_NSDictionary_block(NSDictionary *dict, id(^block)(id memo, id obj)) {
    return ASTReduce(dict.allValues, block);
}

id __ASTReduce_NSDictionary_memo_block(NSDictionary *dict, id memo, id(^block)(id memo, id obj)) {
    return ASTReduce(dict.allValues, memo, block);
}

id __ASTReduce_NSFastEnumeration_block(id<NSFastEnumeration> collection, id(^block)(id memo, id obj)) {
    NSCParameterAssert(block != nil);

    id current;

    BOOL firstRun = YES;
    for (id obj in collection) {
        if (firstRun) {
            current = obj;
            firstRun = NO;
            continue;
        }

        current = block(current, obj);
    }

    return current;
}

id __ASTReduce_NSFastEnumeration_memo_block(id<NSFastEnumeration> collection, id memo, id(^block)(id memo, id obj)) {
    NSCParameterAssert(block != nil);

    id current = memo;

    for (id obj in collection) {
        current = block(current, obj);
    }

    return current;
}

#pragma mark - ASTReject.m

NSArray *__ASTReject_NSArray(NSArray *array, BOOL(^block)(id)) {
    NSCParameterAssert(block != nil);

    return ASTFilter(array, ASTNegate(block));
}

NSArray *__ASTReject_NSArray_withIndex(NSArray *array, BOOL(^block)(id, NSUInteger)) {
    NSCParameterAssert(block != nil);

    return ASTFilter(array, ASTNegate(block));
}

NSDictionary *__ASTReject_NSDictionary(NSDictionary *dict, BOOL(^block)(id)) {
    NSCParameterAssert(block != nil);

    return ASTFilter(dict, ASTNegate(block));
}

NSDictionary *__ASTReject_NSDictionary_keysAndValues(NSDictionary *dict, BOOL(^block)(id key, id obj)) {
    NSCParameterAssert(block != nil);

    return ASTFilter(dict, ASTNegate(block));
}

NSSet *__ASTReject_NSSet(NSSet *set, BOOL(^block)(id obj)) {
    NSCParameterAssert(block != nil);

    return ASTFilter(set, ASTNegate(block));
}

NSOrderedSet *__ASTReject_NSOrderedSet(NSOrderedSet *set, BOOL(^block)(id obj)) {
    NSCParameterAssert(block != nil);

    return ASTFilter(set, ASTNegate(block));
}

NSOrderedSet *__ASTReject_NSOrderedSet_withIndex(NSOrderedSet *set, BOOL(^block)(id obj, NSUInteger idx)) {
    NSCParameterAssert(block != nil);

    return ASTFilter(set, ASTNegate(block));
}

#pragma mark - ASTShuffle.m

NSArray *__ASTShuffle_NSArray(NSArray *array) {
    NSMutableArray *result = [array mutableCopy];

    for (NSInteger i = result.count - 1; i > 0; i--) {
        [result exchangeObjectAtIndex:arc4random_uniform((u_int32_t)i + 1)
                    withObjectAtIndex:i];
    }

    return result;
}

NSOrderedSet *__ASTShuffle_NSOrderedSet(NSOrderedSet *set) {
    NSMutableOrderedSet *result = [set mutableCopy];

    for (NSInteger i = result.count - 1; i > 0; i--) {
        [result exchangeObjectAtIndex:arc4random_uniform((u_int32_t)i + 1)
                    withObjectAtIndex:i];
    }

    return result;
}

#pragma mark - ASTSize.m

NSUInteger __ASTSize_NSArray(NSArray *array) {
    return array.count;
}

NSUInteger __ASTSize_NSDictionary(NSDictionary *dictionary) {
    return dictionary.count;
}

NSUInteger __ASTSize_NSSet(NSSet *set) {
    return set.count;
}

NSUInteger __ASTSize_NSOrderedSet(NSOrderedSet *set) {
    return set.count;
}

NSUInteger __ASTSize_NSFastEnumeration(id<NSFastEnumeration> collection) {
    NSUInteger size = 0;

    for (__attribute__((unused)) id _ in collection) size++;

    return size;
}

#pragma mark - ASTSort.m

#pragma mark - Helpers

static NSComparator const ASTSort_Compare = ^NSComparisonResult(id a, id b) {
    return [a compare:b];
};

#pragma mark - Sort

NSArray *__ASTSort_NSArray(NSArray *array) {
    return __ASTSort_NSArray_comparator(array, ASTSort_Compare);
}

NSArray *__ASTSort_NSArray_comparator(NSArray *array, NSComparator comparator) {
    NSCParameterAssert(comparator != nil);

    return [array sortedArrayUsingComparator:comparator];
}

NSOrderedSet *__ASTSort_NSOrderedSet(NSOrderedSet *set) {
    return __ASTSort_NSOrderedSet_comparator(set, ASTSort_Compare);
}

NSOrderedSet *__ASTSort_NSOrderedSet_comparator(NSOrderedSet *set, NSComparator comparator) {
    NSCParameterAssert(comparator != nil);

    if (set == nil) return nil;

    return [NSOrderedSet orderedSetWithArray:[set sortedArrayUsingComparator:comparator]];
}

#pragma mark - ASTTail.m

NSArray *__ASTTail_NSArray(NSArray *array) {
    if (array == nil) return nil;

    if (array.count <= 1) return @[];

    NSRange range = NSMakeRange(1, array.count - 1);

    return [array subarrayWithRange:range];
}

NSOrderedSet *__ASTTail_NSOrderedSet(NSOrderedSet *set) {
    if (set == nil) return nil;

    if (set.count <= 1) return [NSOrderedSet orderedSet];

    NSRange range = NSMakeRange(1, set.count - 1);

    return [NSOrderedSet orderedSetWithArray:[set.array subarrayWithRange:range]];
}

#pragma mark - ASTUnion.m

NSArray *__ASTUnion_NSArray(NSArray *array, NSArray *other) {
    if (array == nil) return other;
    if (other == nil) return array;

    return [array arrayByAddingObjectsFromArray:ASTDifference(other, array)];
}

NSSet *__ASTUnion_NSSet(NSSet *set, NSSet *other) {
    if (set == nil) return other;
    if (other == nil) return set;

    return [set setByAddingObjectsFromSet:other];
}

NSOrderedSet *__ASTUnion_NSOrderedSet(NSOrderedSet *set, NSOrderedSet *other) {
    if (set == nil) return other;
    if (other == nil) return set;

    NSMutableOrderedSet *result = [set mutableCopy];
    [result unionOrderedSet:other];

    return result;
}

#pragma mark - ASTWithout.m

NSArray *__ASTWithout_NSArray(NSArray *collection, id obj) {
    return ASTReject(collection, ^BOOL(id other) {
        return [obj isEqual:other];
    });
}

NSSet *__ASTWithout_NSSet(NSSet *set, id obj) {
    return ASTReject(set, ^BOOL(id other) {
        return [obj isEqual:other];
    });
}

NSOrderedSet *__ASTWithout_NSOrderedSet(NSOrderedSet *set, id obj) {
    return ASTReject(set, ^BOOL(id other) {
        return [obj isEqual:other];
    });
}
