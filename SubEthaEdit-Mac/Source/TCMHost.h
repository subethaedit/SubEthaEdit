//  TCMHost.h
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Mar 03 2004.

#import <Foundation/Foundation.h>


@interface TCMHost : NSObject {
    CFHostRef I_host;
    NSMutableArray *I_names;
    unsigned short I_port;
    NSMutableArray *I_addresses;
    NSDictionary *I_userInfo;
}

@property (nonatomic, weak) id delegate;
@property (nonatomic, strong, readonly) NSDictionary *userInfo;


+ (TCMHost *)hostWithName:(NSString *)name port:(unsigned short)port userInfo:(NSDictionary *)userInfo;
+ (TCMHost *)hostWithAddressData:(NSData *)addr port:(unsigned short)port userInfo:(NSDictionary *)userInfo;

- (instancetype)initWithName:(NSString *)name port:(unsigned short)port userInfo:(NSDictionary *)userInfo;
- (instancetype)initWithAddressData:(NSData *)addr port:(unsigned short)port userInfo:(NSDictionary *)userInfo;

- (NSArray *)addresses;
- (NSArray *)names;

- (void)checkReachability;
- (void)resolve;
- (void)reverseLookup;
- (void)cancel;

@end


@interface NSObject (TCMHostDelegateAdditions)
- (void)host:(TCMHost *)sender didNotResolve:(NSError *)error;
- (void)hostDidResolveAddress:(TCMHost *)sender;
- (void)hostDidResolveName:(TCMHost *)sender;
@end
