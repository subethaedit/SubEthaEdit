//  LMPTOMLSerialization.m
//
//  Created by dom on 10/20/18.
//  Copyright © 2018 Lone Monkey Productions. All rights reserved.

#import "LMPTOMLSerialization.h"

// make map ordered so the output is canonical
#define CPPTOML_USE_MAP
#include "cpptoml.h"
#include "LMP_cpptoml_visitors.h"

#include <iostream>
#include <istream>
#include <streambuf>
#include <string>

NSErrorDomain const LMPTOMLErrorDomain = @"productions.monkey.lone.TOML";
static NSInteger const LMPTOMLParseErrorCode = 7031;
static NSInteger const LMPTOMLWriteErrorCode = 7001;

struct membuf : std::streambuf {
    membuf(char* begin, char* end) {
        this->setg(begin, begin, end);
    }
};

@implementation LMPTOMLSerialization

+ (NSDictionary <NSString *, id>*)TOMLObjectWithData:(NSData *)data error:(NSError **)error {
    try {
        char *bytes = (char *)data.bytes;
        membuf sbuf(bytes, bytes + data.length);
        std::istream in(&sbuf);
        cpptoml::parser p{in};
        std::shared_ptr<cpptoml::table> g = p.parse();
//        std::cout << (*g) << std::endl;
        
        // convert table to standard Objective-C objects
        toml_nsdictionary_writer dw;
        g->accept(dw);
        NSDictionary *result = dw.dictionary();
        
        return result;
    } catch (const cpptoml::parse_exception& e) {
        if (error) {
            *error = [NSError errorWithDomain:LMPTOMLErrorDomain
                                         code:LMPTOMLParseErrorCode
                                     userInfo:@{
                                                NSLocalizedDescriptionKey : @"Input TOML could not be parsed",
                                                NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"%s", e.what()],
                                                                                      }];
        }
        return nil;
    }
}

static void writeDictionaryToTable(NSDictionary<NSString *, id> *dict, std::shared_ptr<cpptoml::table> table) {
    for (NSString *key in dict.keyEnumerator) {
        auto cppKey = std::string(key.UTF8String);
        auto cppValue = ObjectToValue(dict[key]);
        table->insert(cppKey, cppValue);
    }
}

static std::shared_ptr<cpptoml::base> ObjectToValue(id objectValue) {
    if ([objectValue isKindOfClass:[NSString class]]) {
        NSString *val = objectValue;
        return cpptoml::make_value<std::string>(std::string(val.UTF8String));
    } else if ([objectValue isKindOfClass:[NSNumber class]]) {
        NSNumber *val = objectValue;
        if ((__bridge CFBooleanRef)val == kCFBooleanTrue ||
            (__bridge CFBooleanRef)val == kCFBooleanFalse) {
            return cpptoml::make_value<bool>(val.boolValue);
        } else if (CFNumberIsFloatType((__bridge CFNumberRef)val)) {
            return cpptoml::make_value<double>(val.doubleValue);
        } else {
            return cpptoml::make_value<long long>(val.longLongValue);
        }
    } else if ([objectValue isKindOfClass:[NSArray class]]) {
        if ([[objectValue firstObject] isKindOfClass:[NSDictionary class]]) {
            return ArrayToTableArray(objectValue);
        } else {
            return ArrayToArray(objectValue);
        }
    } else if ([objectValue isKindOfClass:[NSDictionary class]]) {
        return DictionaryToTable(objectValue);
    } else if ([objectValue isKindOfClass:[NSDateComponents class]]) {
        NSDateComponents *dc = objectValue;
        if (YES) {
            if (dc.year == NSDateComponentUndefined) {
                cpptoml::local_time lt;
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
                    lt.microsecond = (int)(dc.nanosecond / 1000);
                }
                return cpptoml::make_value(lt);
            }
            
            cpptoml::local_date ld;
            ld.year = (int)dc.year;
            ld.month = (int)dc.month;
            ld.day = (int)dc.day;
            if (dc.hour == NSDateComponentUndefined) {
                return cpptoml::make_value(ld);
            }
            
            cpptoml::local_datetime ldt;
            static_cast<cpptoml::local_date&>(ldt) = ld;
            ldt.hour = (int)dc.hour;
            ldt.minute = (int)dc.minute;
            ldt.second = (int)dc.second;
            if (dc.nanosecond != NSDateComponentUndefined) {
                ldt.microsecond = (int)(dc.nanosecond / 1000);
            }
            if (!dc.timeZone) {
                return cpptoml::make_value(ldt);
            }
            
            cpptoml::offset_datetime odt;
            static_cast<cpptoml::local_datetime&>(odt) = ldt;
            int minutesFromGMT = (int)[dc.timeZone secondsFromGMT] / 60;
            odt.hour_offset = minutesFromGMT / 60;
            odt.minute_offset = minutesFromGMT % 60;
            return cpptoml::make_value(odt);
        }
        
    } else {
        auto reason = std::string([NSString stringWithFormat:@"%@ cannot be encoded to TOML", objectValue].UTF8String);
        throw std::out_of_range{reason};
    }
}

static std::shared_ptr<cpptoml::table_array> ArrayToTableArray(NSArray *array) {
    auto tarr = cpptoml::make_table_array();
    for (NSDictionary *objectValue in array) {
        tarr->push_back(DictionaryToTable(objectValue));
    }
    return tarr;
}

static std::shared_ptr<cpptoml::array> ArrayToArray(NSArray *array) {
    auto arr = cpptoml::make_array();
    for (id objectValue in array) {
        auto val = ObjectToValue(objectValue);
        if (val->is_value()) {
            // FIXME: there needs to be better cpp foo to make this not be redundant
            if ([objectValue isKindOfClass:[NSString class]]) {
                NSString *val = objectValue;
                arr->push_back(std::string(val.UTF8String));
            } else if ([objectValue isKindOfClass:[NSNumber class]]) {
                NSNumber *val = objectValue;
                if ((__bridge CFBooleanRef)val == kCFBooleanTrue ||
                    (__bridge CFBooleanRef)val == kCFBooleanFalse) {
                    arr->push_back((bool)val.boolValue);
                } else if (CFNumberIsFloatType((__bridge CFNumberRef)val)) {
                    arr->push_back(val.doubleValue);
                } else {
                    arr->push_back(val.longLongValue);
                }
            }
        } else if (val->is_array()) {
            arr->push_back(val->as_array());
        } else if (val->is_table()) {
            arr->push_back(val->as_array());
        }
    }
    return arr;
}


static std::shared_ptr<cpptoml::table> DictionaryToTable(NSDictionary<NSString *, id> *dictionary) {
    auto tbl = cpptoml::make_table();
    writeDictionaryToTable(dictionary, tbl);
    return tbl;
}

+ (NSData *)dataWithTOMLObject:(NSDictionary<NSString *, id> *)tomlObject error:(NSError **)error {
    try {
        auto root = DictionaryToTable(tomlObject);
        
        std::stringstream s("");
        s << *root;
        std::string str = s.str();
        NSData *result = [NSData dataWithBytes:str.data() length:str.length()];
        return result;
    } catch (const std::invalid_argument& e) {
        if (error) {
            *error = [NSError errorWithDomain:LMPTOMLErrorDomain
                                         code:LMPTOMLWriteErrorCode
                                     userInfo:@{
                                                NSLocalizedDescriptionKey : @"Input objects could not be converted to TOML",
                                                NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"%s", e.what()],
                                                }];
        }
        return nil;
    }
}

static NSString *TOMLTimeStringFromComponents(NSDateComponents *dc) {
    NSMutableString *result = [NSMutableString new];
    if (dc.year != NSDateComponentUndefined) {
        [result appendFormat:@"%04d-%02d-%2d", (int)dc.year, (int)dc.month, (int)dc.day];
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

+ (NSDictionary<NSString *, id> *)serializableObjectWithTOMLObject:(NSDictionary<NSString *, id> *)tomlObject {
    NSMutableDictionary *result = [tomlObject mutableCopy];
    for (NSString *key in result.allKeys) {
        id value = result[key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            result[key] = [self serializableObjectWithTOMLObject:value];
        } else if ([value isKindOfClass:[NSArray class]] && [[value firstObject] isKindOfClass:[NSDictionary class]]) {
            NSMutableArray *array = [NSMutableArray new];
            for (NSDictionary *dict in value) {
                [array addObject:[self serializableObjectWithTOMLObject:dict]];
            }
            result[key] = array;
        } else if ([value isKindOfClass:[NSDateComponents class]]) {
            result[key] = TOMLTimeStringFromComponents(value);
        }
    }
    return result;
}

@end
