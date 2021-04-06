// Asterism.h
//
// Amalgamation generated from:
// 44ed990 (Fix typo, Sat Sep 26 13:59:57 2020 +0200)

#import <Foundation/Foundation.h>

#define ASTERISM_OVERLOADABLE static inline __attribute__((overloadable))

#define ASTERISM_USE_INSTEAD(METHOD) __attribute__((deprecated("Don't call this method directly. You should use " # METHOD " instead.")))

#pragma mark - ASTAll.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTAll) BOOL __ASTAll_NSDictionary(NSDictionary *dict, BOOL(NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTAll) BOOL __ASTAll_NSFastEnumeration(id<NSFastEnumeration> collection, BOOL(NS_NOESCAPE ^block)(id obj));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Tests if all values in a dictionary pass a test.
///
/// @param dict  A dictionary of elements.
/// @param block A block that takes a value of @c dict as its only argument and
///              returns @c YES if the value passes the test. The block must no
///              be @c nil .
///
/// @returns @c YES if all values in @c dict pass the test @c block.
ASTERISM_OVERLOADABLE BOOL ASTAll(NSDictionary *dict, BOOL(NS_NOESCAPE ^block)(id obj)) {
    return __ASTAll_NSDictionary(dict, block);
}

/// Tests if all elements in a collection pass a test.
///
/// @param collection A collection of elements.
/// @param block      A block that takes an element as its only argument and
///                   returns @c YES if the element passes the test. The block
///                   must not be @c nil .
///
/// @returns @c YES if all elements in @c collection pass the test @c block.
ASTERISM_OVERLOADABLE BOOL ASTAll(id<NSFastEnumeration> collection, BOOL(NS_NOESCAPE ^block)(id obj)) {
    return __ASTAll_NSFastEnumeration(collection, block);
}

#pragma clang diagnostic pop

#pragma mark - ASTAny.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTAny) BOOL __ASTAny_NSDictionary(NSDictionary *dict, BOOL(NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTAny) BOOL __ASTAny_NSFastEnumeration(id<NSFastEnumeration> collection, BOOL(NS_NOESCAPE ^block)(id obj));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Tests if any value in a dictionary passes a test.
///
/// @param dict  A dictionary of elements.
/// @param block A block that takes a value of @c dict as its only argument and
///              returns @c YES if the value passes the test. The block must no
///              be @c nil .
///
/// @returns @c YES if any of the values in @c dict passes the test @c block.
ASTERISM_OVERLOADABLE BOOL ASTAny(NSDictionary *dict, BOOL(NS_NOESCAPE ^block)(id obj)) {
    return __ASTAny_NSDictionary(dict, block);
}

/// Tests if any element in a collection passes a test.
///
/// @param collection A collection of elements.
/// @param block      A block that takes an element as its only argument and
///                   returns @c YES if the element passes the test. The block
///                   must not be @c nil .
///
/// @returns @c YES if any of the elements in @c collection passes the test
///          @c block.
ASTERISM_OVERLOADABLE BOOL ASTAny(id<NSFastEnumeration> collection, BOOL(NS_NOESCAPE ^block)(id obj)) {
    return __ASTAny_NSFastEnumeration(collection, block);
}

#pragma clang diagnostic pop

#pragma mark - ASTDefaults.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTDefaults) NSDictionary *__ASTDefaults_NSDictionary(NSDictionary *dict, NSDictionary *defaults);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Fills in missing values from another dictionary.
///
/// @param dict     A dictionary.
/// @param defaults A dictionary of default values.
///
/// @returns A new dictionary that contains a union of key-value-pairs of
///          @c dict and @c defaults. Key-value-pairs of @c dict will have
///          precedence over those taken from @c defaults.
ASTERISM_OVERLOADABLE NSDictionary *ASTDefaults(NSDictionary *dict, NSDictionary *defaults) {
    return __ASTDefaults_NSDictionary(dict, defaults);
}

#pragma clang diagnostic pop

#pragma mark - ASTDifference.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTDifference) NSArray *__ASTDifference_NSArray(NSArray *array, NSArray *other);
ASTERISM_USE_INSTEAD(ASTDifference) NSSet *__ASTDifference_NSSet(NSSet *set, NSSet *other);
ASTERISM_USE_INSTEAD(ASTDifference) NSOrderedSet *__ASTDifference_NSOrderedSet(NSOrderedSet *set, NSOrderedSet *other);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Returns the difference between two arrays.
///
/// @param array An array of elements.
/// @param other An array of elements.
///
/// @returns an array containing the elements of @c array that are not present
///          in @c other. The order is being maintained.
ASTERISM_OVERLOADABLE NSArray *ASTDifference(NSArray *array, NSArray *other) {
    return __ASTDifference_NSArray(array, other);
}

/// Returns the difference between two sets.
///
/// @param set   A set of elements.
/// @param other A set of elements.
///
/// @returns A set containing the elements of @c set that are not present in
///          @c other.
ASTERISM_OVERLOADABLE NSSet *ASTDifference(NSSet *set, NSSet *other) {
    return __ASTDifference_NSSet(set, other);
}

/// Returns the difference between two ordered sets.
///
/// @param set   An ordered set of elements.
/// @param other An ordered set of elements.
///
/// @returns An ordered set containing the elements of @c set that are not
///          present in @c other.
ASTERISM_OVERLOADABLE NSOrderedSet *ASTDifference(NSOrderedSet *set, NSOrderedSet *other) {
    return __ASTDifference_NSOrderedSet(set, other);
}

#pragma clang diagnostic pop

#pragma mark - ASTEach.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTEach) void __ASTEach_NSArray(NSArray *array, void(NS_NOESCAPE ^iterator)(id obj));
ASTERISM_USE_INSTEAD(ASTEach) void __ASTEach_NSArray_withIndex(NSArray *array, void(NS_NOESCAPE ^iterator)(id obj, NSUInteger idx));
ASTERISM_USE_INSTEAD(ASTEach) void __ASTEach_NSDictionary(NSDictionary *dict, void(NS_NOESCAPE ^iterator)(id obj));
ASTERISM_USE_INSTEAD(ASTEach) void __ASTEach_NSDictionary_keysAndValues(NSDictionary *dict, void(NS_NOESCAPE ^iterator)(id key, id obj));
ASTERISM_USE_INSTEAD(ASTEach) void __ASTEach_NSOrderedSet_withIndex(NSOrderedSet *set, void(NS_NOESCAPE ^iterator)(id obj, NSUInteger idx));
ASTERISM_USE_INSTEAD(ASTEach) void __ASTEach_NSFastEnumeration(id<NSFastEnumeration> enumerable, void(NS_NOESCAPE ^iterator)(id obj));
ASTERISM_USE_INSTEAD(ASTEach) void __ASTEach_NSFastEnumeration_withIndex(id<NSFastEnumeration> enumerable, void(NS_NOESCAPE ^iterator)(id obj, NSUInteger idx));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Iterates over all elements of an array.
///
/// @param array    An array of elements.
/// @param iterator A block that takes an element as its only argument. The
///                 block must not be @c nil .
ASTERISM_OVERLOADABLE void ASTEach(NSArray *array, void(NS_NOESCAPE ^iterator)(id obj)) {
    __ASTEach_NSArray(array, iterator);
}

/// Iterates over all elements of an array, as well as their indexes.
///
/// @param array    An array of elements.
/// @param iterator A block that takes an element and its index in @c array as
///                 its arguments. The block must not be @c nil .
ASTERISM_OVERLOADABLE void ASTEach(NSArray *array, void(NS_NOESCAPE ^iterator)(id obj, NSUInteger idx)) {
    __ASTEach_NSArray_withIndex(array, iterator);
}

/// Iterates over all values of a dictionary.
///
/// @param dict     A dictionary of elements.
/// @param iterator A block that takes an element as its only argument. The
///                 block must not be @c nil .
ASTERISM_OVERLOADABLE void ASTEach(NSDictionary *dict, void(NS_NOESCAPE ^iterator)(id obj)) {
    __ASTEach_NSDictionary(dict, iterator);
}

/// Iterates over all keys and values of a dictionary.
///
/// @param dict     A dictionary of elements.
/// @param iterator A block that takes a key and a value as its arguments. The
///                 block must not be @c nil .
ASTERISM_OVERLOADABLE void ASTEach(NSDictionary *dict, void(NS_NOESCAPE ^iterator)(id key, id obj)) {
    __ASTEach_NSDictionary_keysAndValues(dict, iterator);
}

/// Iterates over all elements of an ordered set, as well as their indexes.
///
/// @param set      An ordered set of elements.
/// @param iterator A block that takes an element and its index in @c set as its
///                 arguments. The block must not be @c nil .
ASTERISM_OVERLOADABLE void ASTEach(NSOrderedSet *set, void(NS_NOESCAPE ^iterator)(id obj, NSUInteger idx)) {
    __ASTEach_NSOrderedSet_withIndex(set, iterator);
}

/// Iterates over elements in a collection.
///
/// @param enumerable An object that implements @c NSFastEnumeration.
/// @param iterator   A block that takes an element as its only argument. The
///                   block must not be @c nil .
ASTERISM_OVERLOADABLE void ASTEach(id<NSFastEnumeration> enumerable, void(NS_NOESCAPE ^iterator)(id obj)) {
    __ASTEach_NSFastEnumeration(enumerable, iterator);
}

/// Iterates over elements in a collection.
///
/// @param enumerable An object that implements @c NSFastEnumeration.
/// @param iterator   A block that takes an element and its index in @c array as
///                   its arguments. The block must not be @c nil .
ASTERISM_OVERLOADABLE void ASTEach(id<NSFastEnumeration> enumerable, void(NS_NOESCAPE ^iterator)(id obj, NSUInteger idx)) {
    __ASTEach_NSFastEnumeration_withIndex(enumerable, iterator);
}

#pragma clang diagnostic pop

#pragma mark - ASTEmpty.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTEmpty) BOOL __ASTEmpty_NSArray(NSArray *array);
ASTERISM_USE_INSTEAD(ASTEmpty) BOOL __ASTEmpty_NSDictionary(NSDictionary *dictionary);
ASTERISM_USE_INSTEAD(ASTEmpty) BOOL __ASTEmpty_NSSet(NSSet *set);
ASTERISM_USE_INSTEAD(ASTEmpty) BOOL __ASTEmpty_NSOrderedSet(NSOrderedSet *set);
ASTERISM_USE_INSTEAD(ASTEmpty) BOOL __ASTEmpty_NSFastEnumeration(id<NSFastEnumeration> collection);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// @returns @c YES if @c array is empty.
ASTERISM_OVERLOADABLE BOOL ASTEmpty(NSArray *array) {
    return __ASTEmpty_NSArray(array);
}

/// @returns @c YES if @c dictionary is empty.
ASTERISM_OVERLOADABLE BOOL ASTEmpty(NSDictionary *dictionary) {
    return __ASTEmpty_NSDictionary(dictionary);
}

/// @returns @c YES if @c set is empty.
ASTERISM_OVERLOADABLE BOOL ASTEmpty(NSSet *set) {
    return __ASTEmpty_NSSet(set);
}

/// @returns @c YES if @c set is empty.
ASTERISM_OVERLOADABLE BOOL ASTEmpty(NSOrderedSet *set) {
    return __ASTEmpty_NSOrderedSet(set);
}

/// @returns @c YES if @c collection is empty.
ASTERISM_OVERLOADABLE BOOL ASTEmpty(id<NSFastEnumeration> collection) {
    return __ASTEmpty_NSFastEnumeration(collection);
}

#pragma clang diagnostic pop

#pragma mark - ASTExtend.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTExtend) NSDictionary *__ASTExtend_NSDictionary(NSDictionary *dict, NSDictionary *source);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Extends a dictionary with values from another dictionary.
///
/// @param dict   A dictionary.
/// @param source A dictionary of extensions.
///
/// @returns A new dictionary that contains a union of key-value-pairs of
///          @c dict and @c source. Key-value-pairs of @c source will have
///          precedence over those taken from @c dict.
ASTERISM_OVERLOADABLE NSDictionary *ASTExtend(NSDictionary *dict, NSDictionary *source) {
    return __ASTExtend_NSDictionary(dict, source);
}

#pragma clang diagnostic pop

#pragma mark - ASTFilter.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTFilter) NSArray *__ASTFilter_NSArray(NSArray *array, BOOL(NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTFilter) NSArray *__ASTFilter_NSArray_withIndex(NSArray *array, BOOL(NS_NOESCAPE ^block)(id obj, NSUInteger idx));
ASTERISM_USE_INSTEAD(ASTFilter) NSDictionary *__ASTFilter_NSDictionary(NSDictionary *dict, BOOL(NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTFilter) NSDictionary *__ASTFilter_NSDictionary_keysAndValues(NSDictionary *dict, BOOL(NS_NOESCAPE ^block)(id key, id obj));
ASTERISM_USE_INSTEAD(ASTFilter) NSSet *__ASTFilter_NSSet(NSSet *set, BOOL(NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTFilter) NSOrderedSet *__ASTFilter_NSOrderedSet(NSOrderedSet *set, BOOL(NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTFilter) NSOrderedSet *__ASTFilter_NSOrderedSet_withIndex(NSOrderedSet *array, BOOL(NS_NOESCAPE ^block)(id obj, NSUInteger idx));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Filters out the elements of an array that fail a test.
///
/// @param array An array of elements.
/// @param block A block that takes an element as its only argument and returns
///              @c YES if the element passes the test.
///              The block must not be @c nil .
///
/// @returns An array of all values in @c array that pass the test. The order is
///          being maintained.
ASTERISM_OVERLOADABLE NSArray *ASTFilter(NSArray *array, BOOL(NS_NOESCAPE ^block)(id obj)) {
    return __ASTFilter_NSArray(array, block);
}

/// Filters out the elements of an array that fail a test.
///
/// @param array An array of elements.
/// @param block A block that takes an element as well as its index in @c array
///              as its arguments and returns @c YES if the element passes the
///              test. The block must not be @c nil .
///
/// @returns an array of all values in @c array that pass the test. The order is
///          being maintained.
ASTERISM_OVERLOADABLE NSArray *ASTFilter(NSArray *array, BOOL(NS_NOESCAPE ^block)(id obj, NSUInteger idx)) {
    return __ASTFilter_NSArray_withIndex(array, block);
}

/// Filters out the values of a dictionary that fail a test.
///
/// @param dict  A dictionary of elements.
/// @param block A block that takes a value of @c dict as its only argument and
///              returns @c YES if the element passes the test.
///              The block must not be @c nil .
///
/// @returns A dictionary of the keys and values in @c dict for which the values
///          passed the test.
ASTERISM_OVERLOADABLE NSDictionary *ASTFilter(NSDictionary *dict, BOOL(NS_NOESCAPE ^block)(id obj)) {
    return __ASTFilter_NSDictionary(dict, block);
}

/// Filters out the keys and values of a dictionary that fail a test.
///
/// @param dict  A dictionary of elements.
/// @param block A block that takes a key and a value of @c dict as its
///              arguments and returns @c YES if the element passes the test.
///              The block must not be @c nil .
///
/// @returns A dictionary of the keys and values in @c dict that passed the
///          test.
ASTERISM_OVERLOADABLE NSDictionary *ASTFilter(NSDictionary *dict, BOOL(NS_NOESCAPE ^block)(id key, id obj)) {
    return __ASTFilter_NSDictionary_keysAndValues(dict, block);
}

/// Filters out the elements of a set that fail a test.
///
/// @param set   A set of elements.
/// @param block A block that takes an element as its only argument and returns
///              @c YES if the element passes the test.
///              The block must not be @c nil .
///
/// @returns A set of all values in @c set that pass the test.
ASTERISM_OVERLOADABLE NSSet *ASTFilter(NSSet *set, BOOL(NS_NOESCAPE ^block)(id obj)) {
    return __ASTFilter_NSSet(set, block);
}

/// Filters out the elements of an ordered set that fail a test.
///
/// @param set   An ordered set of elements.
/// @param block A block that takes an element as its only argument and returns
///              @c YES if the element passes the test.
///              The block must not be @c nil .
///
/// @returns An ordered set of all values in @c set that pass the test.
ASTERISM_OVERLOADABLE NSOrderedSet *ASTFilter(NSOrderedSet *set, BOOL(NS_NOESCAPE ^block)(id obj)) {
    return __ASTFilter_NSOrderedSet(set, block);
}

/// Filters out the elements of an ordered set that fail a test.
///
/// @param set   An ordered set of elements.
/// @param block A block that takes an element as well as its index in @c set as
///              its arguments and returns @c YES if the element passes the
///              test.
///              The block must not be @c nil .
///
/// @returns An ordered set of all values in @c set that pass the test. The
///          order is being maintained.
ASTERISM_OVERLOADABLE NSOrderedSet *ASTFilter(NSOrderedSet *set, BOOL(NS_NOESCAPE ^block)(id obj, NSUInteger idx)) {
    return __ASTFilter_NSOrderedSet_withIndex(set, block);
}

#pragma clang diagnostic pop

#pragma mark - ASTFind.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTFind) id __ASTFind_NSArray(NSArray *array, BOOL(NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTFind) id __ASTFind_NSArray_withIndex(NSArray *array, BOOL(NS_NOESCAPE ^block)(id obj, NSUInteger idx));
ASTERISM_USE_INSTEAD(ASTFind) id __ASTFind_NSDictionary(NSDictionary *dict, BOOL(NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTFind) id __ASTFind_NSDictionary_keysAndValues(NSDictionary *dict, BOOL(NS_NOESCAPE ^block)(id key, id obj));
ASTERISM_USE_INSTEAD(ASTFind) id __ASTFind_NSFastEnumeration(id<NSFastEnumeration> collection, BOOL(NS_NOESCAPE ^block)(id obj));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Finds an element in an array.
///
/// @param array An array of elements.
/// @param block A block that takes an element as its only argument and returns
///              @c YES if it matches the search criteria.
///              The block must not be @c nil .
///
/// @returns The first item in @c array for which @c block returns @c YES or
///          @c nil if no such value was found.
ASTERISM_OVERLOADABLE id ASTFind(NSArray *array, BOOL(NS_NOESCAPE ^block)(id obj)) {
    return __ASTFind_NSArray(array, block);
}

/// Finds an element in an array.
///
/// @param array An array of elements.
/// @param block A block that takes an element and its index in @c array as its
///              arguments and returns @c YES if this is they match the search
///              criteria. The block must not be @c nil .
///
/// @returns The first item in @c array for which @c block returns @c YES or
///          @c nil if no such value was found.
ASTERISM_OVERLOADABLE id ASTFind(NSArray *array, BOOL(NS_NOESCAPE ^block)(id obj, NSUInteger idx)) {
    return __ASTFind_NSArray_withIndex(array, block);
}

/// Finds a value in a dictionary.
///
/// @param dict  A dictionary of elements.
/// @param block A block that takes a value as its argument and returns @c YES
///              if it matches the search criteria.
///              The block must not be @c nil .
///
/// @returns Any value in @c dict for which @c block returns @c YES or @c nil if no
///          such value was found.
ASTERISM_OVERLOADABLE id ASTFind(NSDictionary *dict, BOOL(NS_NOESCAPE ^block)(id obj)) {
    return __ASTFind_NSDictionary(dict, block);
}

/// Finds a value in a dictionary.
///
/// @param dict  A dictionary of elements.
/// @param block A block that takes a key and its value as its arguments and
///              returns @c YES if they match the search criteria.
///              The block must not be @c nil .
///
/// @returns Any value in @c dict for which @c block returns @c YES or @c nil
///          if no such value was found.
ASTERISM_OVERLOADABLE id ASTFind(NSDictionary *dict, BOOL(NS_NOESCAPE ^block)(id key, id obj)) {
    return __ASTFind_NSDictionary_keysAndValues(dict, block);
}

/// Finds a value in a collection.
///
/// @param collection An object that implements @c NSFastEnumeration.
/// @param block      A block that takes an element as its only argument and
///                   returns @c YES if it matches the search criteria.
///                   The block must not be @c nil .
///
/// @returns A value in @c collection for which @c block returns @c YES or
///          @c nil if no such value was found. If @c collection makes an order
///          guarantee, @c ASTFind will return the first value matching the
///          search criteria.
ASTERISM_OVERLOADABLE id ASTFind(id<NSFastEnumeration> collection, BOOL(NS_NOESCAPE ^block)(id obj)) {
    return __ASTFind_NSFastEnumeration(collection, block);
}

#pragma clang diagnostic pop

#pragma mark - ASTFlatten.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTFlatten) NSArray *__ASTFlatten_NSArray(NSArray *array);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Flattens an array a single level.
///
/// @param array An array of elements.
///
/// @returns A new array that concatenates all array elements in @c array while
///          preserving non-array elements.
ASTERISM_OVERLOADABLE NSArray *ASTFlatten(NSArray *array) {
    return __ASTFlatten_NSArray(array);
}

#pragma clang diagnostic pop

#pragma mark - ASTGroupBy.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTGroupBy) NSDictionary *__ASTGroupBy_NSDictionary_block(NSDictionary *dict, id<NSCopying> (NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTGroupBy) NSDictionary *__ASTGroupBy_NSDictionary_keyPath(NSDictionary *dict, NSString *keyPath);
ASTERISM_USE_INSTEAD(ASTGroupBy) NSDictionary *__ASTGroupBy_NSFastEnumeration_block(id<NSFastEnumeration> collection, id<NSCopying> (NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTGroupBy) NSDictionary *__ASTGroupBy_NSFastEnumeration_keyPath(id<NSFastEnumeration> collection, NSString *keyPath);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Groups the values of a dictionary using a block.
///
/// @param dict  A dictionary of elements.
/// @param block A block that takes a value of @c dict as its only argument and
///              returns a key by which to group the value.
///              The return value is required to implement @c NSCopying.
///              The block must not be @c nil .
///
/// @returns A dictionary that maps the keys returned by @c block to a set of all
///          values of @c dict that share the same key.
ASTERISM_OVERLOADABLE NSDictionary *ASTGroupBy(NSDictionary *dict, id<NSCopying> (NS_NOESCAPE ^block)(id obj)) {
    return __ASTGroupBy_NSDictionary_block(dict, block);
}

/// Groups the values of a dictionary by their value for a given key path.
///
/// @param dict    A dictionary of elements.
/// @param keyPath A key path for which the values of @c dict return either an
///                object that implements @c NSCopying or @c nil .
///                This parameter must not be @c nil .
///
/// @returns A dictionary that maps the keys that the values in @c dict return
///          for @c keyPath to a set of all values of @c dict that share the same key.
ASTERISM_OVERLOADABLE NSDictionary *ASTGroupBy(NSDictionary *dict, NSString *keyPath) {
    return __ASTGroupBy_NSDictionary_keyPath(dict, keyPath);
}

/// Groups the elements in a collection using a block.
///
/// @param collection An object that implements @c NSFastEnumeration.
/// @param block      A block that takes an element in @c collection as its only
///                   argument and returns a key by which to group the element.
///                   The return value is required to implement @c NSCopying.
///                   The block must not be @c nil .
///
/// @returns A dictionary that maps the keys returned by @c block to a set of all
///          values in @c collection that share the same key.
///
/// Examples:
/// @code
/// NSArray *numbers = @[ @1, @2, @3, @4, @5 ];
///
/// NSDictionary *grouped = ASTGroupBy(numbers, ^(NSNumber *number){
///     return number.integerValue % 2 == 0 ? @"even" : @"odd";
/// });
///
/// grouped[@"even"]; /// { @2, @4 }
/// grouped[@"odd"];  /// { @1, @3, @5 }
/// @endcode
ASTERISM_OVERLOADABLE NSDictionary *ASTGroupBy(id<NSFastEnumeration> collection, id<NSCopying> (NS_NOESCAPE ^block)(id obj)) {
    return __ASTGroupBy_NSFastEnumeration_block(collection, block);
}

/// Groups the elements in a collection by their value for a given key path.
///
/// @param collection An object that implements @c NSFastEnumeration.
/// @param keyPath    A key path for which the elements in @c collection return
///                   either an object that implements @c NSCopying or @c nil .
///                   This parameter must not be @c nil .
///
/// @returns A dictionary that maps the values the elements return for
///          @c keyPath to a set of all values in @c collection that share
///          the same key.
///
/// Examples
/// @code
/// NSArray *numbers = @[ @"foo", @"bar", @"surprise" ];
///
/// NSDictionary *grouped = ASTGroupBy(numbers, @"length");
///
/// grouped[@3]; /// { @"foo", @"bar" }
/// grouped[@8]; /// { @"surprise" }
/// @endcode
ASTERISM_OVERLOADABLE NSDictionary *ASTGroupBy(id<NSFastEnumeration> collection, NSString *keyPath) {
    return __ASTGroupBy_NSFastEnumeration_keyPath(collection, keyPath);
}

#pragma clang diagnostic pop

#pragma mark - ASTHead.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTHead) id __ASTHead_NSArray(NSArray *array);
ASTERISM_USE_INSTEAD(ASTHead) id __ASTHead_NSOrderedSet(NSOrderedSet *set);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Returns the first element of an array.
///
/// @param array An array of elements.
///
/// @returns The first element or @c nil if the array is empty.
ASTERISM_OVERLOADABLE id ASTHead(NSArray *array) {
    return __ASTHead_NSArray(array);
}

/// Returns the first element of an ordered set.
///
/// @param set An ordered set of elements.
///
/// @returns The first element or @c nil if the ordered set is empty.
ASTERISM_OVERLOADABLE id ASTHead(NSOrderedSet *set) {
    return __ASTHead_NSOrderedSet(set);
}

#pragma clang diagnostic pop

#pragma mark - ASTIndexBy.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTIndexBy) NSDictionary *__ASTIndexBy_NSDictionary_block(NSDictionary *dict, id<NSCopying> (NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTIndexBy) NSDictionary *__ASTIndexBy_NSDictionary_keyPath(NSDictionary *dict, NSString *keyPath);
ASTERISM_USE_INSTEAD(ASTIndexBy) NSDictionary *__ASTIndexBy_NSFastEnumeration_block(id<NSFastEnumeration> collection, id<NSCopying> (NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTIndexBy) NSDictionary *__ASTIndexBy_NSFastEnumeration_keyPath(id<NSFastEnumeration> collection, NSString *keyPath);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Indexes the values of a dictionary using a block.
///
/// @param dict  A dictionary of elements.
/// @param block A block that takes a value of @c dict as its only argument and
///              returns a key by which to index the element.
///              The return value is required to implement @c NSCopying.
///              The block must not be @c nil .
///
/// @returns A dictionary that maps the keys returned by @c block to the
///          respective input value. If @c block returns the same value for
///          multiple values, an arbitrary value is chosen.
ASTERISM_OVERLOADABLE NSDictionary *ASTIndexBy(NSDictionary *dict, id<NSCopying> (NS_NOESCAPE ^block)(id obj)) {
    return __ASTIndexBy_NSDictionary_block(dict, block);
}

/// Indexes the values of a dictionary by their value for a given key path.
///
/// @param dict    A dictionary of elements.
/// @param keyPath A key path for which the values of @c dict return either an
///                object that implements @c NSCopying or @c nil .
///                This parameter must not be @c nil .
///
/// @returns A dictionary that maps the values the elements return for
///          @c keyPath to the respective input value. If multiple values return
///          the same value for @c keyPath, an arbitrary element is chosen.
ASTERISM_OVERLOADABLE NSDictionary *ASTIndexBy(NSDictionary *dict, NSString *keyPath) {
    return __ASTIndexBy_NSDictionary_keyPath(dict, keyPath);
}

/// Indexes the elements of a collection using a block.
///
/// @param collection An object that implements @c NSFastEnumeration.
/// @param block      A block that takes an element in @c collection as its only
///                   argument and returns a key by which to index the element.
///                   The return value is required to implement @c NSCopying.
///                   The block must not be @c nil .
///
/// @returns A dictionary that maps the keys returned by @c block to the
///          respective input value. If @c block returns the same value for
///          multiple values, an arbitrary value is chosen.
///
/// Examples
/// @code
/// NSArray *strings = @[ @"foo", @"bar" ];
///
/// NSDictionary *indexed = ASTIndexBy(strings, ^(NSString *string){
///     return @([string characterAtIndex:0]);
/// });
///
/// indexed[@"f"]; // @"foo"
/// indexed[@"b"]; // @"bar"
/// @endcode
ASTERISM_OVERLOADABLE NSDictionary *ASTIndexBy(id<NSFastEnumeration> collection, id<NSCopying> (NS_NOESCAPE ^block)(id obj)) {
    return __ASTIndexBy_NSFastEnumeration_block(collection, block);
}

/// Indexes the elements in a collection by their value for a given key path.
///
/// @param collection An object that implements @c NSFastEnumeration.
/// @param keyPath    A key path for which the elements in @c collection return
///                   either an object that implements @c NSCopying or @c nil .
///                   This parameter must not be @c nil .
///
/// @returns A dictionary that maps the values the elements return for
///          @c keyPath to the respective input value. If multiple values return
///          the same value for @c keyPath, an arbitrary element is chosen.
///
/// Examples
/// @code
/// NSArray *strings = @[ @"a", @"ab", @"abc" ];
///
/// NSDictionary *indexed = ASTIndexBy(strings, @"length");
///
/// indexed[@1]; // @"a"
/// indexed[@2]; // @"ab"
/// indexed[@3]; // @"abc"
/// @endcode
ASTERISM_OVERLOADABLE NSDictionary *ASTIndexBy(id<NSFastEnumeration> collection, NSString *keyPath) {
    return __ASTIndexBy_NSFastEnumeration_keyPath(collection, keyPath);
}

#pragma clang diagnostic pop

#pragma mark - ASTIndexOf.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTIndexOf) NSUInteger __ASTIndexOf_NSArray(NSArray *array, id obj);
ASTERISM_USE_INSTEAD(ASTIndexOf) NSUInteger __ASTIndexOf_NSOrderedSet(NSOrderedSet *set, id obj);
ASTERISM_USE_INSTEAD(ASTIndexOf) NSUInteger __ASTIndexOf_NSFastEnumeration(id<NSFastEnumeration> collection, id obj);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Finds the index of an object in an array.
///
/// @param array An array of elements.
/// @param obj   The object to find.
///
/// @returns The first index of @c obj in @c array or @c NSNotFound if the
///          object could not be found.
ASTERISM_OVERLOADABLE NSUInteger ASTIndexOf(NSArray *array, id obj) {
    return __ASTIndexOf_NSArray(array, obj);
}

/// Finds the index of an object in an ordered set.
///
/// @param set An ordered set of elements.
/// @param obj The object to find.
///
/// @returns The first index of @c obj in @c set or @c NSNotFound if the object
///          could not be found.
ASTERISM_OVERLOADABLE NSUInteger ASTIndexOf(NSOrderedSet *set, id obj) {
    return __ASTIndexOf_NSOrderedSet(set, obj);
}

/// Finds the index of an object in a collection.
///
/// @param collection A collection of elements.
/// @param obj        The object to find.
///
/// @returns The first index of @c obj in @c collection or @c NSNotFound if the
///          object could not be found. If collection does not make a guarantee
///          regarding its order, such as @c NSSet or @c NSDictionary, the
///          meaning of the return value is undefined.
ASTERISM_OVERLOADABLE NSUInteger ASTIndexOf(id<NSFastEnumeration> collection, id obj) {
    return __ASTIndexOf_NSFastEnumeration(collection, obj);
}

#pragma clang diagnostic pop

#pragma mark - ASTIntersection.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTIntersection) NSArray *__ASTIntersection_NSArray(NSArray *array, NSArray *other);
ASTERISM_USE_INSTEAD(ASTIntersection) NSSet *__ASTIntersection_NSSet(NSSet *set, NSSet *other);
ASTERISM_USE_INSTEAD(ASTIntersection) NSOrderedSet *__ASTIntersection_NSOrderedSet(NSOrderedSet *set, NSOrderedSet *other);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Returns the intersection of two arrays.
///
/// @param array An array of elements.
/// @param other An array of elements.
///
/// @returns An array containing the elements of @c array that are also present
///          in @c other. The order is being maintained.
ASTERISM_OVERLOADABLE NSArray *ASTIntersection(NSArray *array, NSArray *other) {
    return __ASTIntersection_NSArray(array, other);
}

/// Returns the difference between two sets.
///
/// @param set   A set of elements.
/// @param other A set of elements.
///
/// @returns A set containing the elements of @c set that are also present in
///          @c other.
ASTERISM_OVERLOADABLE NSSet *ASTIntersection(NSSet *set, NSSet *other) {
    return __ASTIntersection_NSSet(set, other);
}

/// Returns the difference between two ordered sets.
///
/// @param set   An ordered set of elements.
/// @param other An ordered set of elements.
///
/// @returns A set containing the elements of @c set that are also present in
///          @c other. The order is being maintained.
ASTERISM_OVERLOADABLE NSOrderedSet *ASTIntersection(NSOrderedSet *set, NSOrderedSet *other) {
    return __ASTIntersection_NSOrderedSet(set, other);
}

#pragma clang diagnostic pop

#pragma mark - ASTMap.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTMap) NSArray *__ASTMap_NSArray(NSArray *array, id(NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTMap) NSArray *__ASTMap_NSArray_withIndex(NSArray *array, id(NS_NOESCAPE ^block)(id obj, NSUInteger idx));
ASTERISM_USE_INSTEAD(ASTMap) NSDictionary *__ASTMap_NSDictionary(NSDictionary *dict, id(NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTMap) NSDictionary *__ASTMap_NSDictionary_keysAndValues(NSDictionary *dict, id(NS_NOESCAPE ^block)(id key, id obj));
ASTERISM_USE_INSTEAD(ASTMap) NSSet *__ASTMap_NSSet(NSSet *set, id(NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTMap) NSOrderedSet *__ASTMap_NSOrderedSet(NSOrderedSet *set, id(NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTMap) NSOrderedSet *__ASTMap_NSOrderedSet_withIndex(NSOrderedSet *array, id(NS_NOESCAPE ^block)(id obj, NSUInteger idx));
ASTERISM_USE_INSTEAD(ASTMap) NSArray *__ASTMap_NSFastEnumeration(id<NSFastEnumeration> collection, id(NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTMap) NSArray *__ASTMap_NSFastEnumeration_withIndex(id<NSFastEnumeration> collection, id(NS_NOESCAPE ^block)(id obj, NSUInteger idx));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Maps a block across an array.
///
/// @param array An array of elements.
/// @param block A block that takes an element as its only argument and returns
///              a new element. The block must not be @c nil .
///
/// @returns An array that contains all values of @c array after @c block has
///          been applied. If @c block returns @c nil . the element is not
///          present in the returned array. The order is being maintained.
ASTERISM_OVERLOADABLE NSArray *ASTMap(NSArray *array, id(NS_NOESCAPE ^block)(id obj)) {
    return __ASTMap_NSArray(array, block);
}

/// Maps a block across an array.
///
/// @param array An array of elements.
/// @param block A block that takes an element and its index in @c array as its
///              arguments and returns a new element. The block must not be
///              @c nil .
///
/// @returns An array that contains all values of @c array after @c block has
///          been applied. If @c block returns @c nil , the element is not
///          present in the returned array. The order is being maintained.
ASTERISM_OVERLOADABLE NSArray *ASTMap(NSArray *array, id(NS_NOESCAPE ^block)(id obj, NSUInteger idx)) {
    return __ASTMap_NSArray_withIndex(array, block);
}

/// Maps a block across a dictionary.
///
/// @param dict  A dictionary of elements.
/// @param block A block that takes a value as its only argument and returns a
///              new value. The block must not be @c nil .
///
/// @returns A dictionary that contains all keys and values of @c dict after
///          @c block has been applied to the value. If @c block returns
///          @c nil , the key and value are not present in the returned
///          dictionary.
ASTERISM_OVERLOADABLE NSDictionary *ASTMap(NSDictionary *dict, id(NS_NOESCAPE ^block)(id obj)) {
    return __ASTMap_NSDictionary(dict, block);
}

/// Maps a block across a dictionary.
///
/// @param dict  A dictionary of elements.
/// @param block A block that takes a key and a value as its arguments and
///              returns a new value. The block must not be @c nil .
///
/// @returns A dictionary that contains all keys and values of @c dict after
///          @c block has been applied to them. If @c block returns @c nil m the
///          key and value are not present in the returned dictionary.
ASTERISM_OVERLOADABLE NSDictionary *ASTMap(NSDictionary *dict, id(NS_NOESCAPE ^block)(id key, id obj)) {
    return __ASTMap_NSDictionary_keysAndValues(dict, block);
}

/// Maps a block across a set.
///
/// @param set   A set of elements.
/// @param block A block that takes an element as its only argument and returns
///              a new element. The block must not be @c nil .
///
/// @returns A set that contains all values of @c set after @c block has been
///          applied. If @c block returns @c nil , the element is not present in
///          the returned set.
ASTERISM_OVERLOADABLE NSSet *ASTMap(NSSet *set, id(NS_NOESCAPE ^block)(id obj)) {
    return __ASTMap_NSSet(set, block);
}

/// Maps a block across an ordered set.
///
/// @param set   An ordered set of elements.
/// @param block A block that takes an element as its only argument and returns
///              a new element. The block must not be @c nil .
///
/// @returns An ordered set that contains all values of @c set after @c block
///          has been applied. If @c block returns @c nil , the element is not
///          present in the returned set. The order is being maintained.
ASTERISM_OVERLOADABLE NSOrderedSet *ASTMap(NSOrderedSet *set, id(NS_NOESCAPE ^block)(id obj)) {
    return __ASTMap_NSOrderedSet(set, block);
}

/// Maps a block across an ordered set.
///
/// @param set   An ordered set of elements.
/// @param block A block that takes an element and its index in @c set as its
///              arguments and returns a new element. The block must not be @c nil .
///
/// @returns An ordered set that contains all values of @c set after @c block has
///          been applied. If @c block returns @c nil , the element is not
///          present in the returned set. The order is being maintained.
ASTERISM_OVERLOADABLE NSOrderedSet *ASTMap(NSOrderedSet *set, id(NS_NOESCAPE ^block)(id obj, NSUInteger idx)) {
    return __ASTMap_NSOrderedSet_withIndex(set, block);
}

/// Maps a block across a collection
///
/// @param collection A collection of elements.
/// @param block      A block that takes an element as its only argument and
///                   returns a new element. The block must not be @c nil .
///
/// @returns An array that contains all values of @c collection after @c block
///          has been applied. If @c block returns @c nil . the element is not
///          present in the returned array. The order is being maintained.
ASTERISM_OVERLOADABLE NSArray *ASTMap(id<NSFastEnumeration> collection, id(NS_NOESCAPE ^block)(id obj)) {
    return __ASTMap_NSFastEnumeration(collection, block);
}

/// Maps a block across a collection
///
/// @param collection A collection of elements.
/// @param block      A block that takes an element and its index in @c set as
///                   its arguments and returns a new element.
///                   The block must not be @c nil .
///
/// @returns An array that contains all values of @c collection after @c block
///          has been applied. If @c block returns @c nil . the element is not
///          present in the returned array. The order is being maintained.
ASTERISM_OVERLOADABLE NSArray *ASTMap(id<NSFastEnumeration> collection, id(NS_NOESCAPE ^block)(id obj, NSUInteger idx)) {
    return __ASTMap_NSFastEnumeration_withIndex(collection, block);
}

#pragma clang diagnostic pop

#pragma mark - ASTMinMax.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTMin) id __ASTMin_NSDictionary(NSDictionary *dict);
ASTERISM_USE_INSTEAD(ASTMin) id __ASTMin_NSDictionary_comparator(NSDictionary *dict, NS_NOESCAPE NSComparator comparator);
ASTERISM_USE_INSTEAD(ASTMax) id __ASTMax_NSDictionary(NSDictionary *dict);
ASTERISM_USE_INSTEAD(ASTMax) id __ASTMax_NSDictionary_comparator(NSDictionary *dict, NS_NOESCAPE NSComparator comparator);
ASTERISM_USE_INSTEAD(ASTMin) id __ASTMin_NSFastEnumeration(id<NSFastEnumeration> collection);
ASTERISM_USE_INSTEAD(ASTMin) id __ASTMin_NSFastEnumeration_comparator(id<NSFastEnumeration> collection, NS_NOESCAPE NSComparator comparator);
ASTERISM_USE_INSTEAD(ASTMax) id __ASTMax_NSFastEnumeration(id<NSFastEnumeration> collection);
ASTERISM_USE_INSTEAD(ASTMax) id __ASTMax_NSFastEnumeration_comparator(id<NSFastEnumeration> collection, NS_NOESCAPE NSComparator comparator);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Returns the minimum of the values of a dictionary by invoking @c -compare: .
///
/// @param dict A dictionary of elements.
///
/// @returns The minimum of the values of @c dict comparing all values by
///          invoking  @c -compare: .
ASTERISM_OVERLOADABLE id ASTMin(NSDictionary *dict) {
    return __ASTMin_NSDictionary(dict);
}

/// Returns the minimum of the values of a dictionary by using an
/// @c NSComparator .
///
/// @param dict       A dictionary of elements.
/// @param comparator An @c NSComparator used to compare the values.
///                   This argument must not be @c nil .
///
/// @returns The minimum of the values of @c dict comparing all values using
///          @c comparator .
ASTERISM_OVERLOADABLE id ASTMin(NSDictionary *dict, NS_NOESCAPE NSComparator comparator) {
    return __ASTMin_NSDictionary_comparator(dict, comparator);
}

/// Returns the maximum of the values of a dictionary by invoking @c -compare: .
///
/// @param dict A dictionary of elements.
///
/// @returns The maximum of the values of @c dict comparing all values by
///          invoking @c -compare: .
ASTERISM_OVERLOADABLE id ASTMax(NSDictionary *dict) {
    return __ASTMax_NSDictionary(dict);
}

/// Returns the maximum of the values of a dictionary by using an
/// @c NSComparator .
///
/// @c dict       A dictionary of elements.
/// @c comparator An @c NSComparator used to compare the values.
///               This argument must not be @c nil .
///
/// @returns The maximum of the values of @c dict comparing all values using
///          @c comparator.
ASTERISM_OVERLOADABLE id ASTMax(NSDictionary *dict, NS_NOESCAPE NSComparator comparator) {
    return __ASTMax_NSDictionary_comparator(dict, comparator);
}

/// Returns the minimum of a collection by invoking @c -compare: .
///
/// @c collection An object that implements NSFastEnumeration.
///
/// @returns The minimum of the collection by comparing all values by invoking
///          @c -compare: .
ASTERISM_OVERLOADABLE id ASTMin(id<NSFastEnumeration> collection) {
    return __ASTMin_NSFastEnumeration(collection);
}

/// Returns the minimum of a collection by using an @c NSComparator .
///
/// @param collection An object that implements @c NSFastEnumeration .
/// @param comparator An @c NSComparator used to compare the values.
///                   This argument must not be @c nil .
///
/// @returns The minimum of the collection by comparing all values using
///          @c comparator .
ASTERISM_OVERLOADABLE id ASTMin(id<NSFastEnumeration> collection, NS_NOESCAPE NSComparator comparator) {
    return __ASTMin_NSFastEnumeration_comparator(collection, comparator);
}

/// Returns the maximum of a collection by invoking @c -compare: .
///
/// @param collection An object that implements @c NSFastEnumeration .
///
/// @returns The maximum of the collection by comparing all values by invoking
///          @c -compare: .
ASTERISM_OVERLOADABLE id ASTMax(id<NSFastEnumeration> collection) {
    return __ASTMax_NSFastEnumeration(collection);
}

/// Returns the maximum of a collection by using an @c NSComparator .
///
/// @param collection An object that implements @c NSFastEnumeration .
/// @param comparator An @c NSComparator used to compare the values.
///                   This argument must not be @c nil .
///
/// @returns The maximum of the collection by comparing all values using
///          @c comparator.
ASTERISM_OVERLOADABLE id ASTMax(id<NSFastEnumeration> collection, NS_NOESCAPE NSComparator comparator) {
    return __ASTMax_NSFastEnumeration_comparator(collection, comparator);
}

#pragma clang diagnostic pop

#pragma mark - ASTNegate.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTNegate) BOOL (^__ASTNegate_id(BOOL(^block)(id)))(id);
ASTERISM_USE_INSTEAD(ASTNegate) BOOL (^__ASTNegate_id_id(BOOL(^block)(id, id)))(id, id);
ASTERISM_USE_INSTEAD(ASTNegate) BOOL (^__ASTNegate_id_NSUInteger(BOOL(^block)(id, NSUInteger)))(id, NSUInteger);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Negates a block.
///
/// @param block Takes a single argument of type @c id and returns a @c BOOL .
///              This argument must not be @c nil .
///
/// @returns A new block of the same type that returns the opposite of what
///          @c block returns.
ASTERISM_OVERLOADABLE BOOL (^ASTNegate(BOOL(^block)(id)))(id) {
    return __ASTNegate_id(block);
}

/// Negates a block.
///
/// @param block Takes two arguments of type @c id and returns a @c BOOL .
///              This argument must not be @c nil .
///
/// Returns a new block of the same type that returns the opposite of what
/// @c block returns.
ASTERISM_OVERLOADABLE BOOL (^ASTNegate(BOOL(^block)(id, id)))(id, id) {
    return __ASTNegate_id_id(block);
}

/// Negates a block.
///
/// @params block Takes an argument of type id and one of type @c NSUInteger
///               and returns a @c BOOL.
///               This argument must not be @c nil .
///
/// Returns a new block of the same type that returns the opposite of what
/// @c block returns.
ASTERISM_OVERLOADABLE BOOL (^ASTNegate(BOOL(^block)(id, NSUInteger)))(id, NSUInteger) {
    return __ASTNegate_id_NSUInteger(block);
}

#pragma clang diagnostic pop

#pragma mark - ASTPick.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTPick) NSDictionary *__ASTPick_NSDictionary(NSDictionary *dict, NSArray *keys);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Picks the elements of a dictionary that are contained in a given array.
///
/// @param dict A dictionary of elements.
/// @param keys An array of keys to pick.
///
/// @returns A dictionary of the keys and values in @c dict for which the keys
///          are contained in @c keys.
ASTERISM_OVERLOADABLE NSDictionary *ASTPick(NSDictionary *dict, NSArray *keys) {
    return __ASTPick_NSDictionary(dict, keys);
}

#pragma clang diagnostic pop

#pragma mark - ASTPluck.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTPluck) NSDictionary *__ASTPluck_NSDictionary(NSDictionary *dict, NSString *keyPath);
ASTERISM_USE_INSTEAD(ASTPluck) NSArray *__ASTPluck_NSFastEnumeration(id<NSFastEnumeration> collection, NSString *keyPath);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Extracts a value for a given key path from all values of a dictionary.
///
/// @param dict    A dictionary of elements.
/// @param keyPath A key path. This argument must not be @c nil .
///
/// @returns A dictionary mapping the original keys to the values that the
///          values in @c dict return for @c keyPath. If a value returns
///          @c nil when invoked with @c -valueForKeyPath: , it is not present
///          in the returned dictionary.
ASTERISM_OVERLOADABLE NSDictionary *ASTPluck(NSDictionary *dict, NSString *keyPath) {
    return __ASTPluck_NSDictionary(dict, keyPath);
}

/// Extracts a value for a given key path from all elements in a collection.
///
/// @params collection An object that implements NSFastEnumeration.
/// @params keyPath    A key path. This argument must not be @c nil .
///
/// @returns An array of the values that the elements in @c collection return
///          for @c keyPath. If an element returns @c nil when invoked with
///          @c -valueForKeyPath: , it is not present in the returned array.
///          If possible, the order is being maintained.
ASTERISM_OVERLOADABLE NSArray *ASTPluck(id<NSFastEnumeration> collection, NSString *keyPath) {
    return __ASTPluck_NSFastEnumeration(collection, keyPath);
}

#pragma clang diagnostic pop

#pragma mark - ASTReduce.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTReduce) id __ASTReduce_NSDictionary_block(NSDictionary *dict, id(NS_NOESCAPE ^block)(id memo, id obj));
ASTERISM_USE_INSTEAD(ASTReduce) id __ASTReduce_NSDictionary_memo_block(NSDictionary *dict, id memo, id(NS_NOESCAPE ^block)(id memo, id obj));
ASTERISM_USE_INSTEAD(ASTReduce) id __ASTReduce_NSFastEnumeration_block(id<NSFastEnumeration> collection, id(NS_NOESCAPE ^block)(id memo, id obj));
ASTERISM_USE_INSTEAD(ASTReduce) id __ASTReduce_NSFastEnumeration_memo_block(id<NSFastEnumeration> collection, id memo, id(NS_NOESCAPE ^block)(id memo, id obj));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Reduces a dictionary to a single value.
///
/// @param dict  An object that implements @c NSFastEnumeration .
/// @param block A block that takes two arguments and returns an object.
///              The first argument is its last return value or a value of
///              @c dict when it is called for the first time. The second
///              argument is the next value of @c dict .
///              The block must not be @c nil .
///
/// @returns The last return value of @c block once it reached the end of
///          @c dict . If @c dict has only one value, @c block is never invoked
///          and that value. If @c dict is empty, @c nil is returned.
ASTERISM_OVERLOADABLE id ASTReduce(NSDictionary *dict, id(NS_NOESCAPE ^block)(id memo, id obj)) {
    return __ASTReduce_NSDictionary_block(dict, block);
}

/// Reduces a dictionary to a single value.
///
/// @param dict  An object that implements @c NSFastEnumeration.
/// @param memo  The first argument to @c block when it is invoked for the first time.
/// @param block A block that takes two arguments and returns an object. The
///              first argument is its last return value or @c memo when it is
///              called for the first time. The second argument is the next
///              value of @c dict .
///              The block must not be @c nil .
///
/// @returns The last return value of @c block once it reached the end of
///          @c dict. If @c dict is empty, @c memo is returned.
ASTERISM_OVERLOADABLE id ASTReduce(NSDictionary *dict, id memo, id(NS_NOESCAPE ^block)(id memo, id obj)) {
    return __ASTReduce_NSDictionary_memo_block(dict, memo, block);
}

/// Reduces a collection to a single value.
///
/// @param collection An object that implements @c NSFastEnumeration .
/// @param block      A block that takes two arguments and returns an object.
///                   The first argument is its last return value or the first
///                   element in the @c collection when it is called for the
///                   first time. The second argument is the next value in the
///                   collection, starting with the second one.
///                   The block must not be @c nil .
///
/// @returns The last return value of @c block once it reached the end of
///          @c collection. If @c collection has only one element, @c block is
///          never invoked and the first element is returned.
///          If @c collection is empty, @c nil is returned.
///
/// Example
/// @code
/// NSString *(NS_NOESCAPE ^concat)(NSString *, NSString *) = ^(NSString *a, NSString *b) {
///     return [a stringByAppendingString:b];
/// };
///
/// // Equivalent to [@"a" stringByAppendingString:@"b"];
/// ASTReduce(@[ @"a", @"b" ], concat);
///
/// // Equivalent to [[@"a" stringByAppendingString:@"b"] stringByAppendingString:@"c"];
/// ASTReduce(@[ @"a", @"b", @"c" ], concat);
/// @endcode
ASTERISM_OVERLOADABLE id ASTReduce(id<NSFastEnumeration> collection, id(NS_NOESCAPE ^block)(id memo, id obj)) {
    return __ASTReduce_NSFastEnumeration_block(collection, block);
}

/// Reduces a collection to a single value.
///
/// @param collection An object that implements @c NSFastEnumeration.
/// @param memo       The first argument to @c block when it is invoked for the
///                   first time.
/// @param block      A block that takes two arguments and returns an object.
///                   The first argument is its last return value or @c memo
///                   when it is called for the first time. The second argument
///                   is the next value in the collection, starting with the
///                   first. The block must not be @c nil .
///
/// @returns The last return value of @c block once it reached the end of
///          @c collection. If @c collection is empty, @c memo is returned.
ASTERISM_OVERLOADABLE id ASTReduce(id<NSFastEnumeration> collection, id memo, id(NS_NOESCAPE ^block)(id memo, id obj)) {
    return __ASTReduce_NSFastEnumeration_memo_block(collection, memo, block);
}

#pragma clang diagnostic pop

#pragma mark - ASTReject.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTReject) NSArray *__ASTReject_NSArray(NSArray *array, BOOL(NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTReject) NSArray *__ASTReject_NSArray_withIndex(NSArray *array, BOOL(NS_NOESCAPE ^block)(id obj, NSUInteger idx));
ASTERISM_USE_INSTEAD(ASTReject) NSDictionary *__ASTReject_NSDictionary(NSDictionary *dict, BOOL(NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTReject) NSDictionary *__ASTReject_NSDictionary_keysAndValues(NSDictionary *dict, BOOL(NS_NOESCAPE ^block)(id key, id obj));
ASTERISM_USE_INSTEAD(ASTReject) NSSet *__ASTReject_NSSet(NSSet *set, BOOL(NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTReject) NSOrderedSet *__ASTReject_NSOrderedSet(NSOrderedSet *set, BOOL(NS_NOESCAPE ^block)(id obj));
ASTERISM_USE_INSTEAD(ASTReject) NSOrderedSet *__ASTReject_NSOrderedSet_withIndex(NSOrderedSet *set, BOOL(NS_NOESCAPE ^block)(id obj, NSUInteger idx));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Filters out the elements of an array that pass a test.
///
/// @param array An array of elements.
/// @param block A block that takes an element as its only argument and returns
///              @c YES if the element passes the test. The block must not be
///              @c nil .
///
/// @returns An array of all values in @c array that fail the test. The order is
///          being maintained.
ASTERISM_OVERLOADABLE NSArray *ASTReject(NSArray *array, BOOL(NS_NOESCAPE ^block)(id obj)) {
    return __ASTReject_NSArray(array, block);
}

/// Filters out the elements of an array that pass a test.
///
/// @param array An array of elements.
/// @param block A block that takes an element as well as its index in @c array
///              as its arguments and returns @c YES if the element passes the
///              test. The block must not be @c nil .
///
/// @returns An array of all values in @c array that fail the test. The order is
///          being maintained.
ASTERISM_OVERLOADABLE NSArray *ASTReject(NSArray *array, BOOL(NS_NOESCAPE ^block)(id obj, NSUInteger idx)) {
    return __ASTReject_NSArray_withIndex(array, block);
}

/// Filters out the values of a dictionary that pass a test.
///
/// @param dict  A dictionary of elements.
/// @param block A block that takes a value of @c dict as its only argument and
///              returns @c YES if the element passes the test.
///              The block must not be @c nil .
///
/// @returns A dictionary of the keys and values in @c dict for which the values
///          failed the test.
ASTERISM_OVERLOADABLE NSDictionary *ASTReject(NSDictionary *dict, BOOL(NS_NOESCAPE ^block)(id obj)) {
    return __ASTReject_NSDictionary(dict, block);
}

/// Filters out the keys and values of a dictionary that pass a test.
///
/// @param dict  A dictionary of elements.
/// @param block A block that takes a key and a value of @c dict as its
///              arguments and returns @c YES if the element passes the test.
///              The block must not be @c nil .
///
/// @returns A dictionary of the keys and values in @c dict that fail the test.
ASTERISM_OVERLOADABLE NSDictionary *ASTReject(NSDictionary *dict, BOOL(NS_NOESCAPE ^block)(id key, id obj)) {
    return __ASTReject_NSDictionary_keysAndValues(dict, block);
}

/// Filters out the elements of a set that pass a test.
///
/// @param set   A set of elements.
/// @param block A block that takes an element as its only argument and returns
///              @c YES if the element passes the test.
///              The block must not be @c nil .
///
/// @returns A set of all values in @c set that fail the test.
ASTERISM_OVERLOADABLE NSSet *ASTReject(NSSet *set, BOOL(NS_NOESCAPE ^block)(id obj)) {
    return __ASTReject_NSSet(set, block);
}

/// Filters out the elements of an ordered set that pass a test.
///
/// @param set   An ordered set of elements.
/// @param block A block that takes an element as its only argument and returns
///              @c YES if the element passes the test.
///              The block must not be @c nil .
///
/// @returns An ordered set of all values in @c set that fail the test.
ASTERISM_OVERLOADABLE NSOrderedSet *ASTReject(NSOrderedSet *set, BOOL(NS_NOESCAPE ^block)(id obj)) {
    return __ASTReject_NSOrderedSet(set, block);
}

/// Filters out the elements of an ordered set that pass a test.
///
/// @param set   An ordered set of elements.
/// @param block A block that takes an element as well as its index in @c set
///              as its arguments and returns @c YES if the element passes the
///              test. The block must not be @c nil .
///
/// @returns An ordered set of all values in @c set that fail the test.
///          The order  is being maintained.
ASTERISM_OVERLOADABLE NSOrderedSet *ASTReject(NSOrderedSet *set, BOOL(NS_NOESCAPE ^block)(id obj, NSUInteger idx)) {
    return __ASTReject_NSOrderedSet_withIndex(set, block);
}

#pragma clang diagnostic pop

#pragma mark - ASTShuffle.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTShuffle) NSArray *__ASTShuffle_NSArray(NSArray *array);
ASTERISM_USE_INSTEAD(ASTShuffle) NSOrderedSet *__ASTShuffle_NSOrderedSet(NSOrderedSet *set);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Shuffles an array.
///
/// @param array An array of elements.
///
/// @returns A copy of @c array shuffled using the Fisher-Yates shuffle.
ASTERISM_OVERLOADABLE NSArray *ASTShuffle(NSArray *array) {
    return __ASTShuffle_NSArray(array);
}

/// Shuffles an ordered set.
///
/// @param set - An ordered set of elements.
///
/// @returns A copy of @c set shuffled using the Fisher-Yates shuffle.
ASTERISM_OVERLOADABLE NSOrderedSet *ASTShuffle(NSOrderedSet *set) {
    return __ASTShuffle_NSOrderedSet(set);
}

#pragma clang diagnostic pop

#pragma mark - ASTSize.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTSize) NSUInteger __ASTSize_NSArray(NSArray *array);
ASTERISM_USE_INSTEAD(ASTSize) NSUInteger __ASTSize_NSDictionary(NSDictionary *dictionary);
ASTERISM_USE_INSTEAD(ASTSize) NSUInteger __ASTSize_NSSet(NSSet *set);
ASTERISM_USE_INSTEAD(ASTSize) NSUInteger __ASTSize_NSOrderedSet(NSOrderedSet *set);
ASTERISM_USE_INSTEAD(ASTSize) NSUInteger __ASTSize_NSFastEnumeration(id<NSFastEnumeration> collection);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// The number of values in an array.
///
/// @param array An array of elements.
///
/// @returns The size of @c array.
ASTERISM_OVERLOADABLE NSUInteger ASTSize(NSArray *array) {
    return __ASTSize_NSArray(array);
}

/// The number of values in a dictionary.
///
/// @pram dictionary A dictionary of elements.
///
/// @returns The size of @c dictionary.
ASTERISM_OVERLOADABLE NSUInteger ASTSize(NSDictionary *dictionary) {
    return __ASTSize_NSDictionary(dictionary);
}

/// The number of values in a set.
///
/// @param set A set of elements.
///
/// @returns The size of @c set.
ASTERISM_OVERLOADABLE NSUInteger ASTSize(NSSet *set) {
    return __ASTSize_NSSet(set);
}

/// The number of values in an ordered set.
///
/// @param set An ordered set of elements.
///
/// @returns The size of @c set.
ASTERISM_OVERLOADABLE NSUInteger ASTSize(NSOrderedSet *set) {
    return __ASTSize_NSOrderedSet(set);
}

/// Counts the number of elements in a collection.
///
/// @param collection A collection of elements.
///
/// @returns The size of @c collection in O(n).
ASTERISM_OVERLOADABLE NSUInteger ASTSize(id<NSFastEnumeration> collection) {
    return __ASTSize_NSFastEnumeration(collection);
}

#pragma clang diagnostic pop

#pragma mark - ASTSort.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTSort) NSArray *__ASTSort_NSArray(NSArray *array);
ASTERISM_USE_INSTEAD(ASTSort) NSArray *__ASTSort_NSArray_comparator(NSArray *array, NS_NOESCAPE NSComparator comparator);
ASTERISM_USE_INSTEAD(ASTSort) NSOrderedSet *__ASTSort_NSOrderedSet(NSOrderedSet *set);
ASTERISM_USE_INSTEAD(ASTSort) NSOrderedSet *__ASTSort_NSOrderedSet_comparator(NSOrderedSet *set, NS_NOESCAPE NSComparator comparator);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Sorts an array using @c -compare: .
///
/// @param array An array of elements.
///
/// @returns A copy of @c array, sorted using @c -compare: .
ASTERISM_OVERLOADABLE NSArray *ASTSort(NSArray *array) {
    return __ASTSort_NSArray(array);
}

/// Sorts an array using a custom comparator.
///
/// @param array      An array of elements.
/// @param comparator An @c NSComparator used to compare the values.
///                   This argument must not be @c nil .
///
/// @returns A copy of @c array, sorted using @c comparator.
ASTERISM_OVERLOADABLE NSArray *ASTSort(NSArray *array, NS_NOESCAPE NSComparator comparator) {
    return __ASTSort_NSArray_comparator(array, comparator);
}

/// Sorts an ordered set using @c  -compare: .
///
/// @param set An ordered set of elements.
///
/// @returns A copy of @c set, sorted using @c -compare: .
ASTERISM_OVERLOADABLE NSOrderedSet *ASTSort(NSOrderedSet *set) {
    return __ASTSort_NSOrderedSet(set);
}

/// Sorts an ordered set using a custom comparator.
///
/// @param set        An ordered set of elements.
/// @param comparator An @c NSComparator used to compare the values.
///                   This argument must not be @c nil .
///
/// @returns A copy of @c set, sorted using @c comparator.
ASTERISM_OVERLOADABLE NSOrderedSet *ASTSort(NSOrderedSet *set, NS_NOESCAPE NSComparator comparator) {
    return __ASTSort_NSOrderedSet_comparator(set, comparator);
}

#pragma clang diagnostic pop

#pragma mark - ASTTail.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTTail) NSArray *__ASTTail_NSArray(NSArray *array);
ASTERISM_USE_INSTEAD(ASTTail) NSOrderedSet *__ASTTail_NSOrderedSet(NSOrderedSet *set);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Returns all elements of an array after the first one.
///
/// @param array An array of elements.
///
/// @returns All elements after the first one. If the array has less than one
///          element, an empty array is returned.
ASTERISM_OVERLOADABLE NSArray *ASTTail(NSArray *array) {
    return __ASTTail_NSArray(array);
}

/// Returns all elements of an ordered set after the first one.
///
/// @param set An ordered set of elements.
///
/// @returns All elements after the first one. If the set has less than one
///          element, an empty ordered set is returned.
ASTERISM_OVERLOADABLE NSOrderedSet *ASTTail(NSOrderedSet *set) {
    return __ASTTail_NSOrderedSet(set);
}

#pragma clang diagnostic pop

#pragma mark - ASTUnion.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTUnion) NSArray *__ASTUnion_NSArray(NSArray *array, NSArray *other);
ASTERISM_USE_INSTEAD(ASTUnion) NSSet *__ASTUnion_NSSet(NSSet *set, NSSet *other);
ASTERISM_USE_INSTEAD(ASTUnion) NSOrderedSet *__ASTUnion_NSOrderedSet(NSOrderedSet *set, NSOrderedSet *other);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Returns the union of two arrays.
///
/// @param array An array of elements.
/// @param other An array of elements.
///
/// @returns An array containing all elements of @c array, concatenated with all
///          elements of @c other not already present in @c array.
///          The order is being maintained.
ASTERISM_OVERLOADABLE NSArray *ASTUnion(NSArray *array, NSArray *other) {
    return __ASTUnion_NSArray(array, other);
}

/// Returns the union two sets.
///
/// @param set   A set of elements.
/// @param other A set of elements.
///
/// @returns A set containing the elements of @c set and @c other.
ASTERISM_OVERLOADABLE NSSet *ASTUnion(NSSet *set, NSSet *other) {
    return __ASTUnion_NSSet(set, other);
}

/// Returns the union of two ordered sets.
///
/// @param set   An orderd set of elements.
/// @param other An orderd set of elements.
///
/// @returns An orderd set containing all elements of @c set, concatenated with
///          all elements of @c other not already present in @c set.
///          The order is being maintained.
ASTERISM_OVERLOADABLE NSOrderedSet *ASTUnion(NSOrderedSet *set, NSOrderedSet *other) {
    return __ASTUnion_NSOrderedSet(set, other);
}

#pragma clang diagnostic pop

#pragma mark - ASTWithout.h

// You should not call these methods directly.
ASTERISM_USE_INSTEAD(ASTWithout) NSArray *__ASTWithout_NSArray(NSArray *array, id obj);
ASTERISM_USE_INSTEAD(ASTWithout) NSSet *__ASTWithout_NSSet(NSSet *set, id obj);
ASTERISM_USE_INSTEAD(ASTWithout) NSOrderedSet *__ASTWithout_NSOrderedSet(NSOrderedSet *set, id obj);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Filters out the elements of an array that are equal to a given value.
///
/// @param array An array of elements.
/// @param obj   An element to be removed.
///
/// @returns An array of all values in @c array that are not equal to @c obj.
///          The order is being maintained.
ASTERISM_OVERLOADABLE NSArray *ASTWithout(NSArray *array, id obj) {
    return __ASTWithout_NSArray(array, obj);
}

/// Filters out the elements of a set that are equal to a given value.
///
/// @param set A set of elements.
/// @param obj An element to be removed.
///
/// @returns A set of all values in @c set that are not equal to @c obj.
ASTERISM_OVERLOADABLE NSSet *ASTWithout(NSSet *set, id obj) {
    return __ASTWithout_NSSet(set, obj);
}

/// Filters out the elements of an ordered set that are equal to a given value.
///
/// @param set An ordered set of elements.
/// @param obj An element to be removed.
///
/// @returns An ordered set of all values in @c set that are not equal to
///          @c obj. The order is being maintained.
ASTERISM_OVERLOADABLE NSOrderedSet *ASTWithout(NSOrderedSet *set, id obj) {
    return __ASTWithout_NSOrderedSet(set, obj);
}

#pragma clang diagnostic pop
