//  URLDataProtocol.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Sun Oct 19 2003.

#import "URLDataProtocol.h"


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

- (void)setCachedURLResponse:(NSCachedURLResponse *)aCachedURLResponse {
    [I_cachedURLResponse autorelease];
    I_cachedURLResponse=[aCachedURLResponse retain];
}

-(instancetype)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id <NSURLProtocolClient>)client {
    self=[super initWithRequest:request cachedResponse:cachedResponse client:client];
    if (self) {
        [self setCachedURLResponse:cachedResponse];
//        NSLog(@"didInit");
    }
    return self;
}

-(void)dealloc {
    [I_cachedURLResponse release];
    [super dealloc];
}

-(NSCachedURLResponse *)cachedResponse {
//    NSLog(@"cachedResponse");
    return I_cachedURLResponse;
}

-(void)startLoading {
//    NSLog(@"start loading");
    id <NSURLProtocolClient> client=[self client];
    NSURLRequest *request=[self request];
    NSURLResponse *response=[[NSURLResponse alloc] initWithURL:[request URL] MIMEType:@"text/html" expectedContentLength:[[request HTTPBody] length] textEncodingName:[request valueForHTTPHeaderField:@"LocalContentAndThisIsTheEncoding"]];
    NSCachedURLResponse *cachedResponse=[[[NSCachedURLResponse alloc] initWithResponse:response data:[[self request] HTTPBody] userInfo:nil storagePolicy:NSURLCacheStorageAllowedInMemoryOnly] autorelease];
    [self setCachedURLResponse:cachedResponse];
//    [client URLProtocol:self cachedResponseIsValid:[self cachedResponse]];
    [client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];
    [client URLProtocol:self didLoadData:[[self request] HTTPBody]];
    [client URLProtocolDidFinishLoading:self];
    [response release];
}

-(void)stopLoading {

}

@end
