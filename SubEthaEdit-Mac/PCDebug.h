/*
 *  PCDebug.h
 *
 *  Requires Mac OS X 10.0 or higher
 *
 *	-------------------------------------------------------------------
 */

#import <Foundation/Foundation.h>

#ifndef PC_DEBUG_H_
#define PC_DEBUG_H_

#if defined(__cplusplus)
extern "C" {
#endif // defined(__cplusplus)

#define PCExceptionName @"PCException"

/*	FYI the do-while structures are needed for correct parsing... for instance if
	they were not there this statement would expand incorrectly in non-debug 
	builds:
	
	if ( blah )
	{
		some statements;
	}
	else
		PCLog(@"stuff");
	
	Side note, I got this trick from the definition of _NSAssertBody... pretty
	cool I thought (although slightly confusing) :)
	
	Side note 2, these will get compiled out, it's just for the parser
*/

#define PCRaiseException(condition, ...) do { \
	if (!(condition)) { \
		PCRaiseExceptionFailed(__PRETTY_FUNCTION__, self, __FILE__, __LINE__, [NSString stringWithFormat:__VA_ARGS__]); \
	} \
} while (0)

// <http://zathras.de/angelweb/blog-safe-key-value-coding.htm>
#if DEBUG
#define PROPERTY(propName) NSStringFromSelector(@selector(propName))
#else
#define PROPERTY(propName) @#propName
#endif
	
// This is a memory management tool for annotating method names that do not follow typical naming conventions. See:
// http://clang-analyzer.llvm.org/annotations.html#attr_ns_returns_not_retained
// For some reason it seems as of now (2/21/2011) that NS_RETURNS_RETAINED is defined in the frameworks, but now NS_RETURNS_NOT_RETAINED is not.
	
#ifndef __has_feature      // Optional.
#define __has_feature(x) 0 // Compatibility with non-clang compilers.
#endif
	
#ifndef NS_RETURNS_NOT_RETAINED
#if __has_feature(attribute_ns_returns_not_retained)
#define NS_RETURNS_NOT_RETAINED __attribute__((ns_returns_not_retained))
#else
#define NS_RETURNS_NOT_RETAINED
#endif
#endif
	
#if DEBUG

	#define PCDebugAssert(condition, ...) do { \
		if (!(condition)) { \
			PCDebugAssertFailed(_cmd, self, __FILE__, __LINE__, [NSString stringWithFormat:__VA_ARGS__]); \
		} \
	} while (0)

	#define PCDebugCAssert(condition, ...) do { \
		if (!(condition)) { \
			PCDebugCAssertFailed(__PRETTY_FUNCTION__, __FILE__, __LINE__, [NSString stringWithFormat:__VA_ARGS__]); \
		} \
	} while (0)
	
	#define PCDebugLoggingIsEnabled() 1

	#define PCLog(...) \
		NSLog(@"%@:%d: %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:__VA_ARGS__])
	
	#define PCDebugUnimplementedBySubclass() do { \
		PCLog(@"%@ not implemented by subclass", NSStringFromSelector(_cmd)); \
		[self doesNotRecognizeSelector:_cmd]; \
	} while (0)
	
#else

	#if IS_BETA

		#define PCDebugAssert(condition, ...) do { \
			if (!(condition)) { \
				PCDebugAssertFailed(_cmd, self, __FILE__, __LINE__, [NSString stringWithFormat:__VA_ARGS__]); \
			} \
		} while (0)

		#define PCDebugCAssert(condition, ...) do { \
			if (!(condition)) { \
				PCDebugCAssertFailed(__PRETTY_FUNCTION__, __FILE__, __LINE__, [NSString stringWithFormat:__VA_ARGS__]); \
			} \
		} while (0)

	#else

		#define PCDebugAssert(condition, ...) do { \
			if (!(condition)) { \
				NSLog(@"CONDITION FAILED: %@", [NSString stringWithFormat:__VA_ARGS__]); \
			} \
		} while (0)

		#define PCDebugCAssert(condition, ...) do { \
			if (!(condition)) { \
				NSLog(@"CONDITION FAILED: %@", [NSString stringWithFormat:__VA_ARGS__]); \
			} \
		} while (0)

	#endif // IS_BETA
	
	static inline BOOL PCDebugLoggingIsEnabled() __attribute__((pure));
	static inline BOOL PCDebugLoggingIsEnabled()
	{
		static BOOL sDidCheck; // once per compilation unit
		static SInt32 sEnabled;
		
		if ( !sDidCheck )
		{
			sDidCheck = YES;

#if !TARGET_OS_IPHONE
			sEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DebugLogging"];
			if ( sEnabled )
				NSLog(@"DEBUG LOGGING IS ON");
#endif
		}
		
		return sEnabled;
	}
	
	#define PCLog(...) do { \
		if ( PCDebugLoggingIsEnabled() ) NSLog(__VA_ARGS__); \
	} while (0)
	
	#define PCDebugUnimplementedBySubclass() do { \
		PCLog(@"%@ not implemented by subclass", _cmd); \
	} while (0)

#endif // DEBUG


// PCSelectorOfCaller() returns the SEL of the current method's caller (remember, _cmd is always the SEL of the current method)
#if defined(__x86_64__)

	#define PCSelectorOfCaller() ({ SEL caller; \
		__asm__ ("movq 32(%%rbp), %0" \
				 : "=q"(caller) \
				 : ); \
		caller; \
	})

#elif defined(__i386__)

	#define PCSelectorOfCaller() ({ SEL caller; \
		__asm__ ("movl (%%ebp), %0\n\t" \
				 "movl 12(%0), %0" \
				 : "=q"(caller) \
				 : ); \
		caller; \
	})

#else

	// unimplemented for PPC archs
	#define PCSelectorOfCaller() ""

#endif // defined(__x86_64__)


// "assert" macros are traditionally compiled away completely in release (NDEBUG) builds. To ensure the condition is to be executed even in release builds if ever PCDebugAssert is also compiled away, these "require" macros should be used instead.
#define PCDebugRequire PCDebugAssert
#define PCDebugCRequire PCDebugCAssert


static inline void
PCRaiseExceptionFailed(const char* functionCString, id object, const char* fileCString, int lineNumber, NSString* description)
{
	NSString* file = [NSString stringWithCString:fileCString encoding:NSUTF8StringEncoding];
	NSString* reason = [NSString stringWithFormat:@"%@\n\nfile:%@\nfunction:%s\nline:%d", description, file, functionCString, lineNumber];
	NSException* exception = [NSException exceptionWithName:PCExceptionName reason:reason userInfo:nil];
	
	[exception raise];
}

#if (DEBUG || IS_BETA)

static inline void
PCDebugAssertFailed(SEL method, id object, const char* fileCString, int lineNumber, NSString* description)
{
	NSString* file = [NSString stringWithCString:fileCString encoding:NSUTF8StringEncoding];
	
	[[NSAssertionHandler currentHandler] handleFailureInMethod:method object:object file:file lineNumber:lineNumber description:description];
}

static inline void
PCDebugCAssertFailed(const char* functionCString, const char* fileCString, int lineNumber, NSString* description)
{
	NSString* function = [NSString stringWithCString:functionCString encoding:NSUTF8StringEncoding];
	NSString* file = [NSString stringWithCString:fileCString encoding:NSUTF8StringEncoding];
	
	[[NSAssertionHandler currentHandler] handleFailureInFunction:function file:file lineNumber:lineNumber description:description];
}

#endif // (DEBUG || IS_BETA)

#if defined(__cplusplus)
}
#endif // defined(__cplusplus)

#endif // PC_DEBUG_H_
