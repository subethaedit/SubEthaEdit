//
//  SEEWorkspaceTreeDelegate.m
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 19.08.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import "SEEWorkspaceTreeDelegate.h"
#import "SEEFSTreeNode.h"

@implementation SEEWorkspaceTreeDelegate

-(NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(NSTreeNode *)node {
    SEEFSTreeNode *item = node.representedObject;
    NSString *identifier = @"DataCell";
    NSTableCellView *view = [outlineView makeViewWithIdentifier:identifier
                                  owner:nil];
    view.textField.stringValue = item.name;
    view.imageView.image = item.icon;
    return view;
}

@end
