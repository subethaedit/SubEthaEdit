//  URLDataProtocol.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Sun Oct 19 2003.

#import "URLDataProtocol.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@interface URLDataProtocol ()
@property (nonatomic, strong) NSCachedURLResponse *cachedURLResponse;
@end

@implementation URLDataProtocol

+ (void)initialize {
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if ([request HTTPBody])
        if ([request valueForHTTPHeaderField:@"LocalContentAndThisIsTheEncoding"])
            return YES;
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}


- (instancetype)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id <NSURLProtocolClient>)client {
    self=[super initWithRequest:request cachedResponse:cachedResponse client:client];
    if (self) {
        [self setCachedURLResponse:cachedResponse];
//        NSLog(@"didInit");
    }
    return self;
}

- (void)startLoading {
//    NSLog(@"start loading");
    id <NSURLProtocolClient> client=[self client];
    NSURLRequest *request=[self request];
    NSURLResponse *response=[[NSURLResponse alloc] initWithURL:[request URL] MIMEType:@"text/html" expectedContentLength:[[request HTTPBody] length] textEncodingName:[request valueForHTTPHeaderField:@"LocalContentAndThisIsTheEncoding"]];
    NSCachedURLResponse *cachedResponse=[[NSCachedURLResponse alloc] initWithResponse:response data:[[self request] HTTPBody] userInfo:nil storagePolicy:NSURLCacheStorageAllowedInMemoryOnly];
    [self setCachedURLResponse:cachedResponse];
//    [client URLProtocol:self cachedResponseIsValid:[self cachedResponse]];
    [client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];
    [client URLProtocol:self didLoadData:[[self request] HTTPBody]];
    [client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {

}

@end
