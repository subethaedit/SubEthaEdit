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
#import "PopUpButton.h"

static void *SEERootChildrenChangedContext = (void *)&SEERootChildrenChangedContext;

@interface SEEWorkspaceFileTreeViewController ()

@property (nonatomic, strong) IBOutlet NSTreeController *treeController;
@property (nonatomic, strong) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, strong) IBOutlet PopUpButton *optionsButton;
@property (nonatomic, strong) IBOutlet NSMenu *optionsMenu;

@property (nonatomic, assign) BOOL showHidden;
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
    
    [tree removeObserver:self forKeyPath:@"root.children"];
    tree = [[SEEFSTree alloc] initWithURL:self.workspace.baseURL];
    [tree addObserver:self forKeyPath:@"root.children" options:0 context:SEERootChildrenChangedContext];
    
    
    [self.treeController setContent:tree.root.children];
    
    [self.outlineView expandItem:[self.outlineView itemAtRow:0]];

    self.treeController.sortDescriptors = @[
                                            [NSSortDescriptor sortDescriptorWithKey:@"isLeaf" ascending:YES],
                                            [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
}

-(void)selectFileWithURL:(NSURL *)url {
    NSIndexPath *indexPath = [tree.root nodeForPath:url.filePathURL.path].indexPath;
    
    if (!indexPath) {
        return;
    }
    
    NSTreeNode *controllerNode = self.treeController.arrangedObjects;
    SEEFSTreeNode *node = tree.root;
    
    
    for (NSUInteger position = 0; position < indexPath.length; position++) {
        NSUInteger index = [indexPath indexAtPosition:position];
        node = [[node children] objectAtIndex:index];
        
        controllerNode = [[controllerNode childNodes] SEE_firstObjectPassingTest:^BOOL(NSTreeNode * treeNode) {
            return [treeNode.representedObject isEqual:node];
        }];
    }
    
    self.treeController.selectionIndexPath = controllerNode.indexPath;
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

-(IBAction)toggleShowHidden:(id)sender {
    tree.root.includeHidden = !tree.root.includeHidden;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == SEERootChildrenChangedContext) {
        [self.treeController rearrangeObjects];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)dealloc {
    [tree removeObserver:self forKeyPath:@"root.children"];
}

@end
