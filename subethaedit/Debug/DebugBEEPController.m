//
//  DebugBEEPController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Apr 30 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#ifndef TCM_NO_DEBUG


#import "DebugBEEPController.h"
#import "TCMMMBEEPSessionManager.h"

@implementation DebugBEEPController

- (id)init {
    if ((self = [super initWithWindowNibName:@"DebugBEEP"])) {
        [NSValueTransformer setValueTransformer:[[AddressDataToStringValueTransformer new] autorelease] forName:@"AddressDataToStringValueTransformer"];
    }
    return self;
}

- (void)windowDidLoad
{
    [O_sessionController bind:@"contentArray" toObject:[TCMMMBEEPSessionManager sharedInstance] withKeyPath:@"sessions" options:nil];
}

@end

#pragma mark -

@implementation AddressDataToStringValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;   
}

- (id)transformedValue:(id)value {
    if (![value isKindOfClass:[NSData class]]) return nil;
    return [NSString stringWithAddressData:value];
}

@end


#endif 
