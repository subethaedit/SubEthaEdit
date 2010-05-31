#import "AppController.h"

NSArray*    _names;
NSArray*    _classNames;

@implementation AppController

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

- (void)awakeFromNib
{
    _names = [[NSArray arrayWithObjects:
            @"Shiira Project", @"Black Panel", 
            @"Created by Makoto Kinoshita, HMDT", @"Designed by Kei Sasaki", 
            nil] retain];
    
    _classNames = [[NSArray arrayWithObjects:
            @"HMBlkBox", @"HMBlkButton", @"HMBlkButtonCell", @"HMBlkContentView", 
            @"HMBlkOutlineView", @"HMBlkPanel", @"HMBlkProgressIndicator", @"HMBlkScroller", 
            @"HMBlkScrollView", @"HMBlkSegmentedCell", @"HMBlkSegmentedControl", @"HMBlkTableHaderCell", 
            @"HMBlkTableView", 
            nil] retain];
    
    [_progressIndicator0 setIndeterminate:YES];
    [_progressIndicator0 startAnimation:self];
    
    [_progressIndicator1 setIndeterminate:NO];
    [_progressIndicator1 setMinValue:0.0f];
    [_progressIndicator1 setMaxValue:1.0f];
    [_progressIndicator1 setDoubleValue:0.0f];
    
    [NSTimer scheduledTimerWithTimeInterval:0.5f 
            target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
}

//--------------------------------------------------------------//
#pragma mark -- NSTableView data source --
//--------------------------------------------------------------//

- (int)numberOfRowsInTableView:(NSTableView*)tableView
{
    return [_names count];
}

- (id)tableView:(NSTableView*)tableView 
        objectValueForTableColumn:(NSTableColumn*)tableColumn row:(int)index
{
    return [_names objectAtIndex:index];
}

//--------------------------------------------------------------//
#pragma mark -- NSOutlineView data source --
//--------------------------------------------------------------//

- (id)outlineView:(NSOutlineView*)outlineView 
        child:(int)index 
        ofItem:(id)item
{
    if (!item) {
        return @"Classes";
    }
    
    return [_classNames objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView*)outlineView 
        isItemExpandable:(id)item
{
    if ([item isEqualToString:@"Classes"]) {
        return YES;
    }
    
    return NO;
}

- (int)outlineView:(NSOutlineView*)outlineView 
        numberOfChildrenOfItem:(id)item
{
    if (!item) {
        return 1;
    }
    
    return [_classNames count];
}

- (id)outlineView:(NSOutlineView*)outlineView 
        objectValueForTableColumn:(NSTableColumn*)tableColumn 
        byItem:(id)item
{
    return item;
}

//--------------------------------------------------------------//
#pragma mark -- Progress timer --
//--------------------------------------------------------------//

- (void)timerFired:(NSTimer*)timer
{
    double  value;
    value = [_progressIndicator1 doubleValue];
    
    value += 0.1f;
    if (value > 1.01f) {
        value = 0.0f;
    }
    
    [_progressIndicator1 setDoubleValue:value];
}

@end
