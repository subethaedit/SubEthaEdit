//
//  SEEWorkspaceFileTreeViewController.m
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 03.08.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import "SEEWorkspaceFileTreeViewController.h"
#import "SEEFSTreeNode.h"
#import "SEEWorkspace.h"
#import "SEEWorkspaceTreeDelegate.h"
#import "SEEFSTree.h"

@interface SEEWorkspaceFileTreeViewController ()

@property (nonatomic, strong) IBOutlet NSTreeController *treeController;
@property (nonatomic, strong) IBOutlet NSOutlineView *outlineView;

@end

@implementation SEEWorkspaceFileTreeViewController{
    SEEFSTree *tree;
}

- (instancetype)initWithWorkspace:(SEEWorkspace *)workspace {
    self = [super initWithNibName:@"SEEWorkspaceFileTreeViewController" bundle:nil];
    if (self) {
        self.workspace = workspace;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    tree = [[SEEFSTree alloc] initWithURL:self.workspace.baseURL];
    [self.treeController setContent:tree.root];
    
}

-(void)selectFileWithURL:(NSURL *)url {
    SEEFSTreeNode *node = [tree.root nodeForPath:url.filePathURL.path];
    self.treeController.selectionIndexPath = node.indexPath;
}

- (IBAction)doubleClick:(NSOutlineView *)sender {
    NSUInteger clickedRow = sender.clickedRow;
    id item = [sender itemAtRow:clickedRow];
    SEEFSTreeNode *node = [item representedObject];
    
    if(!node) { return; }
    
    if (!node.isLeaf) {
        if ([sender isItemExpanded:item]) {
            [sender collapseItem:item];
        } else {
            [sender expandItem:item];
        }
        
        return;
    }
    
    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:node.url
                                                                           display:YES completionHandler:^(NSDocument *  document, BOOL documentWasAlreadyOpen, NSError *  error) {
                                                                               
                                                                           }];
}

@end
