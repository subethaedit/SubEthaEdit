//
//  XMLStream.h
//  xmpp
//
//  Created by Martin Ott on Wed Nov 12 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XMLParser;

@interface XMLStream : NSObject {

    NSMutableData *I_readBuffer;
    NSMutableData *I_writeBuffer;
    
    NSInputStream *I_inputStream;
    NSOutputStream *I_outputStream;
    
    XMLParser *I_parser;
}

- (void)writeData:(NSData *)aData;
- (void)connectToHost:(NSHost *)aHost;

- (void)readBytes;
- (void)writeBytes;

@end
