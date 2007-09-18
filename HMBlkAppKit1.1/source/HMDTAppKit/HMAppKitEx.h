/*
HMAppKitEx.h

Author: Makoto Kinoshita

Copyright 2004-2006 The Shiira Project. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted 
provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this list of conditions 
  and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice, this list of 
  conditions and the following disclaimer in the documentation and/or other materials provided 
  with the distribution.

THIS SOFTWARE IS PROVIDED BY THE SHIIRA PROJECT ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE SHIIRA PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.
*/

#import <Cocoa/Cocoa.h>

struct _frFlags {
    unsigned int defeatTitleWrap:1;
    unsigned int resizeByIncrement:1;
    unsigned int RESERVED:30;
};

@interface _NSControllerTreeProxy : NSObject 
{
}

- (id)initWithController:(id)fp8;

- (unsigned int)count;

- (id)nodeAtIndexPath:(id)indexPath;
- (id)objectAtIndexPath:(id)indexPath;

- (id)childOfNode:(id)node atIndex:(int)index;
- (unsigned int)countForNode:(id)node;
- (unsigned int)countForIndexPath:(id)indexPath;

- (BOOL)isExpandable:(id)fp8;
- (BOOL)isExpandableAtArrangedObjectIndexPath:(id)indexPath;

@end

@interface _NSArrayControllerTreeNode : NSObject
{
}

- (id)initWithTreeController:(id)controller;
- (void)dealloc;
- (id)description;

- (unsigned int)count;

- (id)observedObject;
- (void)setObservedObject:(id)object;
- (id)parentNode;
- (void)setParentNode:(id)node;
- (id)indexPath;

- (id)nodeAtIndexPath:(id)node;
- (id)subnodeAtIndex:(unsigned int)index;
- (BOOL)allowsSubnodeAtIndex:(unsigned int)index;
- (BOOL)isLeaf;
- (id)objectAtIndexPath:(id)indexPath;

- (void)updateSubnodes;

- (void)startObservingModelKeyPath:(id)keyPath;
- (void)observeValueForKeyPath:(id)keyPath ofObject:(id)object change:(id)info context:(void*)context;
- (void)insertObject:(id)object atIndex:(unsigned int)index;
- (id)insertObject:(id)object atIndexPath:(id)indexPath;
- (void)removeObjectAtIndex:(unsigned int)index;
- (void)removeObjectAtIndexPath:(id)indexPath;
- (void)prune;
- (void)setSortDescriptors:(id)sortDescriptors;

@end

@interface NSApplication (private)
- (BOOL)_handleKeyEquivalent:(NSEvent*)event;
@end

@interface NSBezierPath (ellipse)
+ (NSBezierPath*)ellipseInRect:(NSRect)rect withRadius:(float)radius;
@end

@interface NSBrowser (appearance)
- (void)_setBorderType:(NSBorderType)type;
- (NSBorderType)_borderType;
@end

@interface NSCell (appearance)
- (void)_drawFocusRingWithFrame:(NSRect)rect;
- (NSDictionary*)_textAttributes;
@end

@interface NSDocumentController (MIMEType)
- (NSString*)typeFromMIMEType:(NSString*)MIMEType;
@end

@interface NSNextStepFrame : NSView
{
    NSTextFieldCell*    titleCell;
    NSButton*           closeButton;
    NSButton*           minimizeButton;
    unsigned int        styleMask;
    struct _frFlags     fvFlags;
    struct _NSSize      sizingParams;
}
@end

@interface NSNextStepFrame (appearance)
- (float)contentAlpha;
@end

@interface NSImage (Assemble)
+ (NSImage*)imageWithSize:(NSSize)size
		leftImage:(NSImage*)leftImage
		middleImage:(NSImage*)middleImage
		rightImage:(NSImage*)middleImage
		middleRect:(NSRect*)outMiddleRect;
@end

@interface NSImage (Drawing)
- (void)drawInRect:(NSRect)dstRect
		fromRect:(NSRect)srcRect
		operation:(NSCompositingOperation)op
		fraction:(float)delta
		contextRect:(NSRect)ctxRect
		isContextFlipped:(BOOL)flag;
@end

@interface NSObject (_NSArrayControllerTreeNode_methods)
- (id)observedObject;
@end

@interface NSOutlineView (private)
- (void)_sendDelegateWillDisplayCell:(id)cell forColumn:(id)column row:(int)row;
- (void)_sendDelegateWillDisplayOutlineCell:(id)cell inOutlineTableColumnAtRow:(int)row;
@end

@interface NSOutlineView (ExpandingAndCollapsing)
- (void)expandAllItems;
- (void)collapseAllItems;
@end

@interface NSOutlineView (ContextMenu)
- (NSMenu*)menuForEvent:(NSEvent*)event;
- (void)draggedImage:(NSImage*)image 
        endedAt:(NSPoint)point 
        operation:(NSDragOperation)operation;
@end

@interface NSObject (OutlineViewContextMenu)
- (NSMenu*)outlineView:(NSOutlineView*)outlineView menuForEvent:(NSEvent*)event;
@end

@interface NSScroller (private)
- (NSRect)_drawingRectForPart:(int)part;
- (NSRect)rectForPart:(int)part;
@end

@interface NSTableView (private)
- (void)_sendDelegateWillDisplayCell:(id)cell forColumn:(id)column row:(int)row;
- (void)drawRow:(int)row clipRect:(NSRect)rect;
@end

@interface NSTableView (ContextMenu)
- (NSMenu*)menuForEvent:(NSEvent*)event;
@end

@interface NSObject (TableViewContextMenu)
- (NSMenu*)tableView:(NSTableView*)tableView menuForEvent:(NSEvent*)event;
@end

@interface NSToolbar (ToolbarItem)
- (NSToolbarItem*)toolbarItemWithIdentifier:(id)identifier;
@end

@interface NSToolbarItemViewer : NSView
{
    NSToolbarItem *_item;
    id _toolbarView;
    id _labelCell;
    struct _NSRect _labelRect;
    float _labelHeight;
    struct _NSSize _maxViewerSize;
    struct _NSSize _minViewerSize;
    struct _NSRect _minIconFrame;
    struct _NSRect _minLabelFrame;
    double _motionStartTime;
    double _motionDuration;
    struct _NSPoint _motionStartLocation;
    struct _NSPoint _motionDestLocation;
    struct {
        unsigned int drawsIconPart:1;
        unsigned int drawsLabelPart:1;
        unsigned int iconAreaIncludesLabelArea:1;
        unsigned int transparentBackground:1;
        unsigned int labelOnlyShowsAsPopupMenu:1;
        unsigned int inMotion:1;
        unsigned int inRecursiveDisplay:1;
        unsigned int insertionAnimationOptimizationOn:1;
        unsigned int needsViewerLayout:1;
        unsigned int needsModeConfiguration:1;
        unsigned int inPaletteView:1;
        unsigned int UNUSED:21;
    } _tbivFlags;
}

- (id)item;
- (void)_setHighlighted:(BOOL)highlighted displayNow:(BOOL)display;

@end

struct __tbvFlags {
    unsigned int _layoutInProgress:1;
    unsigned int _sizingToFit:1;
    unsigned int _isEditing:1;
    unsigned int _inCustomizationMode:1;
    unsigned int _sourceDragMoves:1;
    unsigned int _enabledAsDragSrc:1;
    unsigned int _enabledAsDragDest:1;
    unsigned int _actingAsPalette:1;
    unsigned int _usePaletteLabels:1;
    unsigned int _validatesItems:1;
    unsigned int _forceItemsToBeMinSize:1;
    unsigned int _forceAllClicksToBeDrags:1;
    unsigned int _wrapsItems:1;
    unsigned int _useGridAlignment:1;
    unsigned int _autosizesToFitHorizontally:1;
    unsigned int transparentBackground:1;
    unsigned int drawsBaseline:1;
    unsigned int shouldOverrideHalftonePhase:1;
    unsigned int weStartedDrag:1;
    unsigned int dragOptimizationOn:1;
    unsigned int dragIsInsideView:1;
    unsigned int insertionOptimizationShouldEndAfterUpdates:1;
    unsigned int wantsKeyboardLoop:1;
    unsigned int clipIndicatorWasFirstResponder:1;
    unsigned int scheduledDelayedValidateVisibleItems:1;
    unsigned int skippedLayoutWhileDisabled:1;
    unsigned int shouldHideAfterKeyboardHotKeyEvent:1;
    unsigned int RESERVED:5;
};

@interface NSToolbarView : NSView
{
    NSToolbar *_toolbar;
    id _clipIndicator;
    NSClipView *_ivClipView;
    NSMutableDictionary *_toolbarItemViewersByItem;
    NSMutableArray *_orderedItemViewers;
    NSToolbarItemViewer *_dragDataItemViewer;
    int _dragDataItemViewerStartIndex;
    BOOL _dragDataItemShouldBeRemoved;
    NSToolbarItemViewer *_dragDataInsertionGapItemViewer;
    struct _NSPoint _dragDataLastPoint;
    BOOL _insertionAnimationRunning;
    struct _NSPoint _halftonePhaseOverrideValue;
    NSToolbarView *_validDestinationForDragsWeInitiate;
    int _layoutEnabledCount;
    struct __tbvFlags _tbvFlags;
    NSResponder *_windowPriorFirstResponder;
}
@end
