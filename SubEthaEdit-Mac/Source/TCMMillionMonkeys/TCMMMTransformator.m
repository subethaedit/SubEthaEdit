//  TCMMMTransformator.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Mar 24 2004.

#import "TCMMMTransformator.h"
#import "TCMMMOperation.h"


static TCMMMTransformator *sharedInstance = nil;

@implementation TCMMMTransformator

+ (TCMMMTransformator *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [TCMMMTransformator new];
    }
    return sharedInstance;
}

- (void)registerTransformationTarget:(id)aTarget selector:(SEL)aSelector forOperationId:(NSString *)anOperationID andOperationID:(NSString *)anotherOperationID {
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(transformOperation:serverOperation:)]];
    [invocation setTarget:aTarget];
    [invocation setSelector:aSelector];
    NSMutableDictionary *dictionary = [I_registeredTransformations objectForKey:anOperationID];
    if (!dictionary) {
        dictionary = [NSMutableDictionary dictionary];
        [I_registeredTransformations setObject:dictionary forKey:anOperationID];
    }
    [dictionary setObject:invocation forKey:anotherOperationID];
    
    dictionary = [I_registeredTransformations objectForKey:anotherOperationID];
    if (!dictionary) {
        dictionary = [NSMutableDictionary dictionary];
        [I_registeredTransformations setObject:dictionary forKey:anotherOperationID];
    }
    [dictionary setObject:invocation forKey:anOperationID];

}


- (instancetype)init {
    self = [super init];
    if (self) {
        I_registeredTransformations = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    [I_registeredTransformations release];
    [super dealloc];
}

- (void)transformOperation:(TCMMMOperation *)anOperation serverOperation:(TCMMMOperation *)aServerOperation {
    NSInvocation *invocation = [[I_registeredTransformations objectForKey:[anOperation operationID]] objectForKey:[aServerOperation operationID]];
    if (invocation) {
        [invocation setArgument:&anOperation atIndex:2];
        [invocation setArgument:&aServerOperation atIndex:3];
        [invocation invoke];
    }
}

@end
