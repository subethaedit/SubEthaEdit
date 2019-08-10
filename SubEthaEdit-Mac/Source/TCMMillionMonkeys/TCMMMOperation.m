//  TCMMMOperation.m
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Mar 19 2004.

#import "TCMMMOperation.h"

NSString * const TCMMMOperationTypeKey = @"ot";

static NSMutableDictionary *sClassForOperationTypeDictionary;

@implementation TCMMMOperation

+ (void)registerClass:(Class)aClass forOperationType:(NSString *)aType {
    if (!sClassForOperationTypeDictionary) {
        sClassForOperationTypeDictionary = [NSMutableDictionary new];
    }
    [sClassForOperationTypeDictionary setObject:aClass forKey:aType];
}

+ (id)operationWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    Class class = [sClassForOperationTypeDictionary objectForKey:[aDictionary objectForKey:TCMMMOperationTypeKey]];
    TCMMMOperation *operation = [[[class alloc] initWithDictionaryRepresentation:aDictionary] autorelease];
    return operation;
}

+ (NSString *)operationID {
    return @"nil";
}

- (instancetype)initWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    self = [super init];
    if (self) {
        [self setUserID:[NSString stringWithUUIDData:[aDictionary objectForKey:@"uid"]]];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    TCMMMOperation *copy = [[[self class] allocWithZone:zone] init];
    [copy setUserID:[self userID]];
    return copy;
}

- (void)dealloc {
    [I_userID release];
    [super dealloc];
}

- (NSDictionary *)dictionaryRepresentation {
    return [NSDictionary dictionaryWithObjectsAndKeys:
                [self operationID], TCMMMOperationTypeKey,
                [NSData dataWithUUIDString:[self userID]], @"uid", nil];
}

- (BOOL)isEqualTo:(id)anObject {
    return (
        [anObject isMemberOfClass:[self class]] &&
        [I_userID isEqualToString:[anObject userID]] &&
        [[self operationID] isEqualToString:[anObject operationID]]
    );
}

- (NSString *)operationID {
    return [[self class] operationID];
}

- (void)setUserID:(NSString *)aUserID {
    [I_userID autorelease];
    I_userID = [aUserID copy];
}

- (NSString *)userID {
    return I_userID;
}


@end
