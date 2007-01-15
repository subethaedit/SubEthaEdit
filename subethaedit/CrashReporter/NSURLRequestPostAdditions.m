//
//  NSURLRequestPostAdditions.m
//  BugShelfTest
//
//  Created by Martin Pittenauer on 25.08.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "NSURLRequestPostAdditions.h"


@implementation NSURLRequest (POSTAdditions)

+ (id)requestWithURL:(NSURL *)theURL postDictionary:(NSDictionary *)theDictionary {

	NSString *boundary = @"0xKhTmLbOuNdArY";

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:theURL];
	[request setHTTPMethod:@"POST"];
	[request addValue:[NSString stringWithFormat:@"multipart/form-data; charset=utf-8; boundary=%@",boundary] forHTTPHeaderField: @"Content-Type"];
	
	NSMutableString *t = [NSMutableString string];
	[t appendString:[NSString stringWithFormat:@"--%@\r\n",boundary]];

    NSEnumerator *enumerator = [theDictionary keyEnumerator];
    NSString *key;
    while (key = [enumerator nextObject]) {
        NSString *object = [theDictionary objectForKey:key];

        [t appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key]];
        [t appendString:object];
    	[t appendString:[NSString stringWithFormat:@"\r\n--%@\r\n",boundary]];
    }
    
    [t deleteCharactersInRange:NSMakeRange([t length]-2,2)];
    [t appendString:@"--\r\n"];

    [request setHTTPBody:[t dataUsingEncoding:NSUTF8StringEncoding]];

    return request;    
}

@end

@implementation NSURLRequest(IgnoreSelfSignedCertificatesAdditions)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host {
    return YES;
}

@end
