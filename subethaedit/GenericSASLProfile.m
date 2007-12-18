//
//  GeneralSASLProfile.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 17.12.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "GenericSASLProfile.h"

// simple: http://www.ietf.org/rfc/rfc4616.txt


@implementation GenericSASLProfile
+ (NSDictionary *)parseBLOBData:(NSData *)aData {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSXMLDocument *document = [[[NSXMLDocument alloc] initWithData:aData options:0 error:nil] autorelease];
    NSXMLElement *blobNode = (NSXMLElement *)[[document nodesForXPath:@"/blob" error:nil] lastObject];
    NSLog(@"%s blobNode:%@",__FUNCTION__,blobNode);
    NSLog(@"%s blobNode Attributes:%@",__FUNCTION__,[blobNode attributes]);
    if ([blobNode attributeForName:@"status"]) {
        [result setObject:[[blobNode attributeForName:@"status"] stringValue] forKey:@"status"];
    }
    NSLog(@"%s base64String:%@",__FUNCTION__,[blobNode stringValue]);
    NSData *data = [NSData dataWithBase64EncodedString:[blobNode stringValue]];
    if (data) {
        [result setObject:data forKey:@"data"];
    }
    return result;
}


+ (NSData *)initialDataForUserName:(NSString *)aUserName password:(NSString *)aPassword profileURI:(NSString *)aProfileURI {
    // first message is [authzid] UTF8NUL authcid UTF8NUL passwd
    // we don't use authzid for now
    NSString *blobContent = [[[NSString stringWithFormat:@"\0\%@\0%@", aUserName, aPassword] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO] base64EncodedStringWithLineLength:0];
    return [[NSString stringWithFormat:@"<blob>%@</blob>",blobContent] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
}

+ (NSDictionary *)replyForChannelRequestWithProfileURI:(NSString *)aProfileURI andData:(NSData *)aData inSession:(TCMBEEPSession *)aSession {
    if ([aProfileURI isEqualToString:TCMBEEPSASLPLAINProfileURI]) {
        NSDictionary *parsedBlobData = [self parseBLOBData:aData];
        NSString *userPasswordString = [[[NSString alloc] initWithData:[parsedBlobData objectForKey:@"data"] encoding:NSUTF8StringEncoding] autorelease];
        NSArray *credentialArray = [userPasswordString componentsSeparatedByString:@"\0"];
        NSLog(@"%s credentials are: %@",__FUNCTION__,credentialArray);
        if ([credentialArray count] != 3) {
            return nil;
        } else if ([[aSession authenticationDelegate] respondsToSelector:@selector(authenticationInformationForCredentials:error:)]) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObject:aProfileURI forKey:@"ProfileURI"];
            id authenticationInformation = [[aSession authenticationDelegate] authenticationInformationForCredentials:[NSDictionary dictionaryWithObjectsAndKeys:[credentialArray objectAtIndex:1],@"username",[credentialArray objectAtIndex:2],@"password",nil] error:nil];
            if (authenticationInformation) {
                NSLog(@"%s authenticationInformationIs:%@",__FUNCTION__,authenticationInformation);
                [aSession setAuthenticationInformation:authenticationInformation];
                [dictionary setObject:[@"<blob status='complete' />" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO] forKey:@"Data"];
            } else {
                [dictionary setObject:[@"<error code='535'>authentication failure</error>" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO] forKey:@"Data"];
            }
            return dictionary;
        }
        return nil;
    } else {
        return nil;
    }
}


@end
