//
//  SEENetworkDocumentRepresentation.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SEENetworkDocumentRepresentation : NSObject
@property (nonatomic, weak) id representedObject;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSImage *fileIcon;
@end
