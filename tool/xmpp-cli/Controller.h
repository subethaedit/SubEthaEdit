//
//  Controller.h
//  xmpp
//
//  Created by Martin Ott on Tue Nov 11 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

extern BOOL endRunLoop;

@class XMLStream;

@interface Controller : NSObject {

    XMLStream *I_XMLStream;
}

- (void)setXMLStream:(XMLStream *)aXMLStream;
- (XMLStream *)XMLStream;

- (void)quit;

@end
