//
//  LMP_cpptoml_visitors.h
//  tomlutil
//
//  Created by dom on 10/20/18.
//  Copyright © 2018 Lone Monkey Productions. All rights reserved.
//

#ifndef LMP_cpptoml_visitors_h
#define LMP_cpptoml_visitors_h

/**
 * A visitor for toml objects that writes to an NSMutableDictionary
 */
class toml_nsdictionary_writer {
public:
    toml_nsdictionary_writer() {
        currentDictionary_ = resultContainer_ = [NSMutableDictionary new];
        currentKey_ = @"TOMLRoot";
    }

    NSDictionary *dictionary() {
        return [resultContainer_[@"TOMLRoot"] copy];
    }

    
    void visit(const cpptoml::value<std::string>& v) {
        id value = [NSString stringWithUTF8String:v.get().c_str()];
        writeValue(value);
    }
    
    void visit(const cpptoml::value<int64_t>& v) {
        id value = [NSNumber numberWithLongLong:v.get()];
        writeValue(value);
    }
    
    void visit(const cpptoml::value<double>& v) {
        id value = [NSNumber numberWithDouble:v.get()];
        writeValue(value);
    }
    
    void visit(const cpptoml::value<cpptoml::local_date>& v) {
        id value = ({
            cpptoml::local_date ld = v.get();
            NSDateComponents *result = [NSDateComponents new];
            result.year = ld.year;
            result.month = ld.month;
            result.day = ld.day;
            result;
        });
        writeValue(value);
    }
    
    void visit(const cpptoml::value<cpptoml::local_time>& v) {
        id value = ({
            cpptoml::local_time ld = v.get();
            NSDateComponents *result = [NSDateComponents new];
            result.hour = ld.hour;
            result.minute = ld.minute;
            result.second = ld.second;
            result.nanosecond = ld.microsecond * 1000;
            result;
        });
        writeValue(value);
    }
    
    void visit(const cpptoml::value<cpptoml::local_datetime>& v) {
        id value = ({
            cpptoml::local_datetime ld = v.get();
            NSDateComponents *result = [NSDateComponents new];
            result.year = ld.year;
            result.month = ld.month;
            result.day = ld.day;
            result.hour = ld.hour;
            result.minute = ld.minute;
            result.second = ld.second;
            result.nanosecond = ld.microsecond * 1000;
            result;
        });
        writeValue(value);
    }
    
    void visit(const cpptoml::value<cpptoml::offset_datetime>& v) {
        id value = ({
            cpptoml::offset_datetime ld = v.get();
            NSDateComponents *result = [NSDateComponents new];
            result.year = ld.year;
            result.month = ld.month;
            result.day = ld.day;
            result.hour = ld.hour;
            result.minute = ld.minute;
            result.second = ld.second;
            result.nanosecond = ld.microsecond * 1000;
            result.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:(ld.hour_offset * 60 + ld.minute_offset) * 60];
            result;
        });
        writeValue(value);
    }
    
    void visit(const cpptoml::value<bool>& v) {
        id value = v.get() ? @YES : @NO;
        writeValue(value);
    }
    
    void visit(const cpptoml::array& arr) {
        withContainerIsDictionary( NO, ^{
            for (auto it = arr.get().begin(); it != arr.get().end(); it++) {
                (*it)->accept(*this);
            }
        });
    }
    
    void visit(const cpptoml::table_array& tarr) {
        
        withContainerIsDictionary( NO, ^{
            auto arr = tarr.get();
            for (auto ait = arr.begin(); ait != arr.end(); ait++) {
                (*ait)->accept(*this);
            }
        });

    }
    
    void visit(const cpptoml::table& t) {
        withContainerIsDictionary( YES, ^{
            for (auto it = t.begin(); it != t.end(); it++) {
                currentKey_ = [NSString stringWithUTF8String:it->first.c_str()];
                it->second->accept(*this);
            }
        });
    }
    
private:

    void withContainerIsDictionary(BOOL isDictionary, dispatch_block_t stuff) {
        NSMutableArray *array = currentArray_;
        NSMutableDictionary *dict = currentDictionary_;
        NSString *key = currentKey_;

        if (isDictionary) {
            NSMutableDictionary *contextDictionary = [NSMutableDictionary new];
            writeValue(contextDictionary);
            
            currentDictionary_ = contextDictionary;
            currentArray_ = nil;
        } else {
            NSMutableArray *contextArray = [NSMutableArray new];
            writeValue(contextArray);
            
            currentArray_ = contextArray;
        }
        
        stuff();
        
        currentKey_ = key;
        currentArray_ = array;
        currentDictionary_ = dict;
    }
    
    void writeValue(id value) {
        if (currentArray_) {
            [currentArray_ addObject:value];
        } else {
            currentDictionary_[currentKey_] = value;
        }
    }
    
    NSMutableDictionary *resultContainer_;
    NSMutableDictionary *currentDictionary_;
    NSString *currentKey_;
    NSMutableArray *currentArray_;
};




#endif /* LMP_cpptoml_visitors_h */
