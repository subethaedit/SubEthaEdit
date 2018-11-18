typedef enum LogLevels {
    AlwaysLogLevel = 0,
    SimpleLogLevel = 1,
    DetailedLogLevel = 2,
    AllLogLevel = 3
} LogLevels;

#ifdef TCM_NO_DEBUG
    #define TCM_BLOCK_DEBUGLOGS 1
#endif

#ifdef TCM_BLOCK_DEBUGLOGS
#define DEBUGLOG(domain, level, format, args...)
#else
#define DEBUGLOG(domain, level, format, args...) \
    do { \
        if (level <= [[NSUserDefaults standardUserDefaults] integerForKey:domain]) { \
            NSString *lineInformation = [NSString stringWithFormat:@"%@:%d, %s", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, __FUNCTION__]; \
            NSString *expandedInformation = [NSString stringWithFormat:format, ##args]; \
            NSLog(@"%@ (%@)", expandedInformation, lineInformation); \
        } \
    } while (0)
#endif
