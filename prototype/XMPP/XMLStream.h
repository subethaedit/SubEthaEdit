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
    
    id I_delegate;
}

- (void)writeData:(NSData *)aData;
- (void)connectToName:(NSString *)aName;
- (void)disconnect;

- (void)readBytes;
- (void)writeBytes;

- (void)setDelegate:(id)aDelegate;
- (id)delegate;

@end

@interface NSObject (XMLStreamDelegateAdditions)

- (void)streamDidOpen:(XMLStream *)aXMLStream;
- (void)stream:(XMLStream *)aXMLStream didReceiveStanza:(Node *)aNode;

@end