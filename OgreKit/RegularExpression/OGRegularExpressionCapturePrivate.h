/*
 * Name: OGRegularExpressionCapturePrivate.h
 * Project: OgreKit
 *
 * Creation Date: Jun 24 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2018 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */


#import <OgreKit/OGRegularExpressionCapture.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OGRegularExpressionMatchPrivate.h>


@interface OGRegularExpressionCapture (Private)

- (id)initWithTreeNode:(OnigCaptureTreeNode*)captureNode 
    index:(NSUInteger)index
    level:(NSUInteger)level 
    parentNode:(OGRegularExpressionCapture*)parentNode 
    match:(OGRegularExpressionMatch*)match;

- (OnigCaptureTreeNode*)_captureNode;

@end
