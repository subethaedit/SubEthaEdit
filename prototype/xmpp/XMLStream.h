//
//  XMLStream.h
//  xmpp
//
//  Created by Martin Ott on Wed Nov 12 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XMLParser, Node;

@interface XMLStream : NSObject {

    NSMutableData *I_readBuffer;
    NSMutableData *I_writeBuffer;
    
    NSInputStream *I_inputStream;
    NSOutputStream *I_outputStream;
    
    XMLParser *I_parser;
    Node *I_streamNode;
    Node *I_stanzaNode;
    Node *I_node;
    int I_depth;
    //NSMutableString *I_foundCharacters;
}

- (void)writeData:(NSData *)aData;
- (void)connectToHost:(NSHost *)aHost;
- (void)disconnect;

- (void)readBytes;
- (void)writeBytes;

@end