//  NSAppleScriptAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 27.03.06.

#import "NSAppleScriptTCMAdditions.h"

@implementation NSAppleEventDescriptor (NSAppleEventDescriptorTCMAdditions)
+ (NSAppleEventDescriptor *)appleEventToCallSubroutine:(NSString *)aSubroutineName {
    // build apple event descriptor
    NSAppleEventDescriptor* targetAddress;
    int pid = [[NSProcessInfo processInfo] processIdentifier];
    targetAddress = [NSAppleEventDescriptor descriptorWithDescriptorType:typeKernelProcessID
                                                                   bytes:&pid
                                                                  length:sizeof(pid)];
    NSAppleEventDescriptor *result = 
        [NSAppleEventDescriptor appleEventWithEventClass:'ascr' //kASAppleScriptSuite
                                                 eventID:'psbr' //kASSubroutineEvent
                                        targetDescriptor:targetAddress 
                                                returnID:kAutoGenerateReturnID
                                           transactionID:kAnyTransactionID];
    [result setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[aSubroutineName lowercaseString]]
                    forKeyword:'snam']; // keyASSubroutineName
    [result setParamDescriptor:[NSAppleEventDescriptor listDescriptor]
                    forKeyword:keyDirectObject];
    return result;
}

// very simple implementation - only understands 1 level deep dictionaries with strings as keys or values
- (NSDictionary *)dictionaryValue {
    
    NSAppleEventDescriptor     *recordAED = [self coerceToDescriptorType:typeAERecord];
    NSMutableDictionary *resultDictionary = [NSMutableDictionary dictionary];
    
    int count = [recordAED numberOfItems];
    int index = 1;
    for (index=1;index<=count;index++) { // AppleScript indexes begin at 1
        AEKeyword keyword = [recordAED keywordForDescriptorAtIndex:index];
        
        if (keyword=='usrf') { //keyASUserRecordFields
            NSAppleEventDescriptor *listAED = [recordAED descriptorAtIndex:index];
            
            int listCount = [listAED numberOfItems];
            int listIndex = 1;
            for (listIndex=1;listIndex<=listCount;listIndex+=2)
            {
                // NSLog([[listAED descriptorAtIndex:listIndex  ] description]);
                id key   = [[[listAED descriptorAtIndex:listIndex  ] stringValue] lowercaseString];
                id value = [[listAED descriptorAtIndex:listIndex+1] stringValue];
                
                if (key && value) {
                    [resultDictionary setObject:value forKey:key];
                }
            }
        } else {
            NSLog(@"what is this: %@", [recordAED descriptorAtIndex:index]);
        }
    }
    
    return (NSDictionary *)resultDictionary;
}
@end
