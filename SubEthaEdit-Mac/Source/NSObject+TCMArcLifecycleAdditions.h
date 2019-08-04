//  NSObject+TCMArcLifecycleAdditions.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 26.02.14.

#import <Foundation/Foundation.h>

extern NSString * const kTCMARCLifeCycleContextObjectKey;

CF_INLINE CFTypeRef TCM_RetainAutorelease(id object) {
    if (object) {
        return CFAutorelease(CFBridgingRetain(object));
    } else {
        return nil;
    }
}

CF_INLINE void *TCM_RetainIntoVoid(id object) {
    if (object) {
        CFTypeRef result = CFBridgingRetain(object);
        return (void *)result;
    } else {
        return nil;
    }
}

CF_INLINE id TCM_ReleaseFromVoid(void *potentialObject) {
    if (potentialObject) {
        return CFBridgingRelease((CFTypeRef)potentialObject);
    } else {
        return nil;
    }
}

@interface NSObject (TCMArcLifecycleAdditions)

/*! adds an object to this object which will be retained until it is unset or the parent object is released
	@param anObject any object, must be able to be retained. If nil, clears the association.
	@param aKey a string key. must not be nil.*/
- (void)TCM_setAssociatedValue:(id)anObject forKey:(NSString *)aKey;
/*! @returns the stored associated value for that key, nil if there is no such object */
- (id)TCM_associatedValueForKey:(NSString *)aKey;

/*! convenience method to just set a context object to use in situation where one needs to use old API that uses (void *)context pointers 
 @param anObject object that needs to be compatbile with storing in an NSMutableDictioanry. nil to clear. (the object is stored using -[self TCM_setAssociatedValue:anObject forKey:kTCMARCLifeCycleContextObjectKey] */
- (void)TCM_setContextObject:(id)anObject;
/*! convenience method to just get a previously stored context object */
- (id)TCM_contextObject;
@end
