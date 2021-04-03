//  TCMMacros.h
//
//  Created by dom on 06.03.20.

#import <Foundation/Foundation.h>

#if defined(__has_attribute) && __has_attribute(objc_boxable)
# define TCM_BOXABLE __attribute__((objc_boxable))
#else
# define TCM_BOXABLE
#endif

#if defined(__cplusplus)
#define let auto const
#else
#define let const __auto_type
#endif

#if defined(__cplusplus)
#define var auto
#else
#define var __auto_type
#endif

#define TCM_ONCE(x) { \
  static dispatch_once_t onceToken; \
  dispatch_once(&onceToken, ^{ \
    x \
  }); \
}

#define TCM_ONCE_AFTER(delay,code) { \
  static dispatch_once_t onceToken; \
  dispatch_once(&onceToken, ^{ \
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ \
    code \
      }); \
  }); \
}

#define TCM_CLAMP(_a,_min,_max) (MIN((_max), MAX((_min),(_a))))

#define TCM_LERP(_p, _a, _b) ({ typeof(_a) __a = (_a); (__a + ((_b) - __a) * (_p));})

/// c-style overloadable - see https://clang.llvm.org/docs/AttributeReference.html#overloadable
#define TCM_OVERLOADABLE static inline __attribute__((overloadable))

/*! usage example
 @implementation ABCPlayerManager
  + (instancetype)playerManager {
   return TCM_SINGLETON(ABCPlayerManager);
  }
 @end
*/
#define TCM_SINGLETON(THECLASS) ({ \
    static THECLASS *sharedInstance = nil; \
    static dispatch_once_t onceToken; \
    dispatch_once(&onceToken, ^{ \
        sharedInstance = [THECLASS new]; \
    }); \
    sharedInstance;\
})

// Not yet supported as of Xcode 11. Hoping that the __has_feature check will work once it does
#ifndef TCM_DIRECT_METHOD
#if __has_feature(objc_direct)
#define TCM_DIRECT_METHOD __attribute__((objc_direct))
#else
#define TCM_DIRECT_METHOD
#endif
#endif


#define __TCM_PASTE__(A,B) A##B

#if !defined(TCM_SCALAR_COMPARE)
#define __TCM_SCALAR_COMPARE_IMPL__(A,B,L) ({ __typeof__(A) __TCM_PASTE__(__a,L) = (A); __typeof__(B) __TCM_PASTE__(__b,L) = (B); (__TCM_PASTE__(__a,L) < __TCM_PASTE__(__b,L)) ? NSOrderedAscending : ((__TCM_PASTE__(__a,L) > __TCM_PASTE__(__b,L)) ? NSOrderedDescending : NSOrderedSame);})
    #define TCM_SCALAR_COMPARE(A,B) __TCM_SCALAR_COMPARE_IMPL__(A,B,__COUNTER__)
#endif

// This is mach absolute time (the monotonic clock of the device in seconds since startup, also used in touch timestamps and most timestamp on the system) as NSTimeInterval
#define TCMCurrentTimestamp CACurrentMediaTime
