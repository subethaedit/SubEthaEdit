//  LMPTOMLSerialization.m
//
//  Created by dom on 10/20/18.
//  Copyright © 2018 Lone Monkey Productions. All rights reserved.

#import "LMPTOMLSerialization.h"

#define TOML11_COLORIZE_ERROR_MESSAGE

// #define TOML11_PRESERVE_COMMENTS_BY_DEFAULT
#include "toml.hpp"

#include <iostream>
#include <istream>
#include <streambuf>
#include <strstream>
#include <string>

#include "LMP_toml_visitors.h"


NSErrorDomain const LMPTOMLErrorDomain = @"productions.monkey.lone.TOML";
static NSInteger const LMPTOMLParseErrorCode = 7031;
static NSInteger const LMPTOMLWriteErrorCode = 7001;

NSString * const LMPTOMLErrorInfoKeyColorizedReason = @"ColoredFailureReason";

extern NSString * const LMPTOMLOptionKeySourceFileURL = @"sourceFileURL";



@implementation LMPTOMLSerialization

+ (NSDictionary <NSString *, id>*)TOMLObjectWithData:(NSData *)data error:(NSError **)error {
    return [self TOMLObjectWithData:data options:nil error:error];
}

+ (NSDictionary <NSString *, id>*)TOMLObjectWithData:(NSData *)data options:(NSDictionary *)options error:(NSError **)error {
    
    try {
        char *bytes = (char *)data.bytes;
        
        // deprecated but seems to do what I want, the implementation previously was missing seek capabilities.
        // see https://stackoverflow.com/questions/13059091/creating-an-input-stream-from-constant-memory#comment115305688_13059195
        std::strstreambuf sbuf(bytes, data.length);
        std::istream stream(&sbuf);
        
        // this works as well, probably does more copying than we need
        // std::istringstream stream(std::string(bytes, data.length));
        
        NSURL *fileSourceURL = options[LMPTOMLOptionKeySourceFileURL];
        
        NSString *filePath = fileSourceURL ? fileSourceURL.relativePath : @"anonymous input";
        
        // parse
        const auto data = toml::parse(stream, filePath.UTF8String);
        
        // convert table to standard Objective-C objects
        toml_nsdictionary_writer dw;
        dw.visit(toml::get<toml::table>(data));
        
        // std::cout << " --- " << data << " --- \n";
        
        NSDictionary *result = dw.dictionary();
        return result;
        
    } catch (const toml::exception& e) {
        if (error) {
            NSString *coloredWhat = @(e.what());
            NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:@"\033\\[\\d+m" options:0 error:nil];
            NSString *cleanWhat = [regEx stringByReplacingMatchesInString:coloredWhat options:0 range:NSMakeRange(0, coloredWhat.length) withTemplate:@""];
            
            *error = [NSError errorWithDomain:LMPTOMLErrorDomain
                                         code:LMPTOMLParseErrorCode
                                     userInfo:@{
                                         NSLocalizedDescriptionKey : @"Input TOML could not be parsed",
                                         NSLocalizedFailureReasonErrorKey : cleanWhat,
                                         LMPTOMLErrorInfoKeyColorizedReason : coloredWhat,
                                     }];
        }
        return nil;
    }
}

static toml::value DictionaryToTable(NSDictionary<NSString *, id> *dict) {
    toml::table table;
    for (NSString *key in dict.keyEnumerator) {
        auto cppKey = std::string(key.UTF8String);
        auto cppValue = ObjectToValue(dict[key]);
        table.insert(std::make_pair(cppKey, cppValue));
    }
    return toml::value(table);
}

static toml::value ArrayToArray(NSArray *array) {
    toml::array result;
    for (id value in array) {
        result.push_back(ObjectToValue(value));
    }
    return toml::value(result);
}

static toml::value ObjectToValue(id objectValue) {
    if ([objectValue isKindOfClass:[NSString class]]) {
        return toml::value(std::string([objectValue UTF8String]));
    } else if ([objectValue isKindOfClass:[NSNumber class]]) {
        if ((__bridge CFBooleanRef)objectValue == kCFBooleanTrue ||
            (__bridge CFBooleanRef)objectValue == kCFBooleanFalse) {
            return toml::value((__bridge CFBooleanRef)objectValue == kCFBooleanTrue);
        } else if (CFNumberIsFloatType((__bridge CFNumberRef)objectValue)) {
            return toml::value([objectValue doubleValue]);
        } else {
            return toml::value([objectValue longLongValue]);
        }
    } else if ([objectValue isKindOfClass:[NSDictionary class]]) {
        return DictionaryToTable(objectValue);
    } else if ([objectValue isKindOfClass:[NSArray class]]) {
        return ArrayToArray(objectValue);
    }   else if ([objectValue isKindOfClass:[NSDateComponents class]]) {
        NSDateComponents *dc = objectValue;
        
        if (dc.year == NSDateComponentUndefined) {
            toml::local_time lt;
            if (dc.hour != NSDateComponentUndefined) {
                lt.hour = (int)dc.hour;
            }
            if (dc.minute != NSDateComponentUndefined) {
                lt.minute = (int)dc.minute;
            }
            if (dc.second != NSDateComponentUndefined) {
                lt.second = (int)dc.second;
            }
            if (dc.nanosecond != NSDateComponentUndefined) {
                lt.nanosecond = (int)(dc.nanosecond % 1000);
                long ms = dc.nanosecond / 1000;
                lt.microsecond = (int)(ms % 1000);
                lt.millisecond = (int)ms / 1000;
            }
            return toml::value(lt);
        } else {
            toml::local_date ld((int16_t)dc.year, (toml::month_t)(dc.month - 1), (uint8_t)dc.day);
            if (dc.second == NSDateComponentUndefined) {
                return toml::value(ld);
            }
            else {
                toml::local_time lt;
                if (dc.hour != NSDateComponentUndefined) {
                    lt.hour = (int)dc.hour;
                }
                if (dc.minute != NSDateComponentUndefined) {
                    lt.minute = (int)dc.minute;
                }
                if (dc.second != NSDateComponentUndefined) {
                    lt.second = (int)dc.second;
                }
                if (dc.nanosecond != NSDateComponentUndefined) {
                    lt.nanosecond = (int)(dc.nanosecond % 1000);
                    long ms = dc.nanosecond / 1000;
                    lt.microsecond = (int)(ms % 1000);
                    lt.millisecond = (int)ms / 1000;
                }
                
                toml::local_datetime ldt(ld, lt);
                if (!dc.timeZone) {
                    return toml::value(ldt);
                } else {
                    int minutesFromGMT = (int)[dc.timeZone secondsFromGMT] / 60;
                    toml::offset_datetime dt(ldt, toml::time_offset(minutesFromGMT / 60, minutesFromGMT % 60));
                    return toml::value(dt);
                }
            }
        }
        
    } else {
        return toml::value("--- unkonwn ---");
    }
}

+ (NSData *)dataWithTOMLObject:(NSDictionary<NSString *, id> *)tomlObject error:(NSError **)error {
    try {
//        __auto_type dict = @{@"test1" : @1, @"testBool" : @YES, @"testString" : @"some string", @"test3.14" : @(M_PI),
//                             @"subtable" : @{ @"two" : @"zwo"},
//                             @"some array" : @[@1, @2, @3],
//                             @"some other array" : @[@"oans", @"zwoa"],
//        };

        auto root = DictionaryToTable(tomlObject);
        std::stringstream s("");
        // setw makes inline tables if they fit
        // std::setprecision(7) e.g. would also set the float precision. we might want that for the future
        s << std::setw(100) << root << std::endl;
        std::string str = s.str();
        NSData *result = [NSData dataWithBytes:str.data() length:str.length()];
        return result;
    } catch (const toml::exception& e) {
        if (error) {
            NSString *coloredWhat = @(e.what());
            NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:@"\033\\[\\d+m" options:0 error:nil];
            NSString *cleanWhat = [regEx stringByReplacingMatchesInString:coloredWhat options:0 range:NSMakeRange(0, coloredWhat.length) withTemplate:@""];
            
            *error = [NSError errorWithDomain:LMPTOMLErrorDomain
                                         code:LMPTOMLWriteErrorCode
                                     userInfo:@{
                                         NSLocalizedDescriptionKey : @"Input objects could not be converted to TOML",
                                         NSLocalizedFailureReasonErrorKey : cleanWhat,
                                         LMPTOMLErrorInfoKeyColorizedReason : coloredWhat,
                                     }];
        }
        return nil;
    }
}

static NSString *TOMLTimeStringFromComponents(NSDateComponents *dc) {
    NSMutableString *result = [NSMutableString new];
    if (dc.year != NSDateComponentUndefined) {
        [result appendFormat:@"%04d-%02d-%02d", (int)dc.year, (int)dc.month, (int)dc.day];
    }
    if (dc.minute != NSDateComponentUndefined) {
        if (result.length > 0) {
            [result appendString:@"T"];
        }
        [result appendFormat:@"%02d:%02d:%02d", (int)dc.hour, (int)dc.minute, (int)dc.second];
        if (dc.nanosecond != NSDateComponentUndefined && dc.nanosecond > 0) {
            [result appendFormat:@".%06d", (int)(dc.nanosecond / 1000)];
        }
        if (dc.timeZone) {
            int minuteOffset = (int)dc.timeZone.secondsFromGMT / 60;
            if (minuteOffset == 0) {
                [result appendString:@"Z"];
            } else {
                [result appendString:minuteOffset > 0 ? @"+" : @"-"];
                [result appendFormat:@"%02d:%02d", ABS(minuteOffset) / 60, ABS(minuteOffset) % 60];
            }
        }
    }
    return result;
}

static NSArray *serializableArray(NSArray *array) {
    NSMutableArray *result = [array mutableCopy];
    NSUInteger index = result.count;
    while (index-- != 0) {
        id value = result[index];
        if ([value isKindOfClass:[NSArray class]]) {
            result[index] = serializableArray(value);
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            result[index] = [LMPTOMLSerialization serializableObjectWithTOMLObject:value];
        } else if ([value isKindOfClass:[NSDateComponents class]]) {
            result[index] = TOMLTimeStringFromComponents(value);
        }
    }
    return result;
}

+ (NSDictionary<NSString *, id> *)serializableObjectWithTOMLObject:(NSDictionary<NSString *, id> *)tomlObject {
    NSMutableDictionary *result = [tomlObject mutableCopy];
    for (NSString *key in result.allKeys) {
        id value = result[key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            result[key] = [self serializableObjectWithTOMLObject:value];
        } else if ([value isKindOfClass:[NSArray class]]) {
            result[key] = serializableArray(value);
        } else if ([value isKindOfClass:[NSDateComponents class]]) {
            result[key] = TOMLTimeStringFromComponents(value);
        }
    }
    return result;
}

@end
