//
//  ExampleTableViewController.m
//  Example
//
//  Created by Max Goedjen on 11/13/12.
//
//

#import "ExampleTableViewController.h"
#import "ExampleSectionHeaderView.h"
#import "ExampleTableViewCell.h"
#import "TUICGAdditions.h"

@implementation ExampleTableViewController

- (void)viewDidLoad {
	self.view.autoresizingMask = TUIViewAutoresizingFlexibleSize;
	self.view.maintainContentOffsetAfterReload = YES;
	self.view.alwaysBounceVertical = YES;
	self.tableView = [[TUITableOutlineView alloc] initWithFrame:self.view.frame];
	self.tableView.alwaysBounceVertical = YES;
	self.tableView.dataSource = self;
	self.tableView.delegate = self;
    self.tableView.allowsMultipleSelection = YES;
    self.tableView.backgroundColor = [NSColor grayColor];
	[self.tableView reloadData];
	self.tableView.maintainContentOffsetAfterReload = YES;
	self.tableView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
	
	TUILabel *headerLabel = [[TUILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
	headerLabel.alignment = TUITextAlignmentCenter;
	headerLabel.backgroundColor = [NSColor clearColor];
	headerLabel.font = [NSFont fontWithName:@"HelveticaNeue-Bold" size:15];
	headerLabel.text = @"Example Header View";
	self.view.headerView = headerLabel;
	
	TUILabel *footerLabel = [[TUILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
	footerLabel.alignment = TUITextAlignmentCenter;
	footerLabel.backgroundColor = [NSColor clearColor];
	footerLabel.font = [NSFont fontWithName:@"HelveticaNeue-Bold" size:15];
	footerLabel.text = @"Example Footer View";
	self.tableView.footerView = footerLabel;
    self.tableView.footerView.backgroundColor = [NSColor redColor];
    
    TUIButton *reloadButton = [TUIButton buttonWithType:TUIButtonTypeStandard];
    [reloadButton addActionForControlEvents:TUIControlEventMouseUpInside block:^{
        [self.tableView reloadData];
    }];
    [reloadButton setImage:[NSImage imageNamed:NSImageNameRefreshTemplate] forState:TUIControlStateNormal];
    reloadButton.frame = CGRectMake(10, 10, 24, 24);
    
    [self.tableView.footerView addSubview:reloadButton];
	
	TUIRefreshControl *refreshControl = [[TUIRefreshControl alloc] initInTableView:self.view];
	refreshControl.tintColor = [NSColor grayColor];
	
	__block __unsafe_unretained TUIRefreshControl *weakRefresh = refreshControl;
	[refreshControl addActionForControlEvents:TUIControlEventValueChanged block:^{
		double delayInSeconds = 3.0;
		TUIRefreshControl *strongRefresh = weakRefresh;
		
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[strongRefresh endRefreshing];
		});
	}];
}

- (NSInteger)numberOfSectionsInTableView:(TUITableView *)tableView {
	return 8;
}

- (NSInteger)tableView:(TUITableView *)table numberOfRowsInSection:(NSInteger)section {
//    return 5;
//    NSLog(@"RQ NUMS");
    NSLog(@"table: %@", table);
 	if ([table isKindOfClass:[TUITableOutlineView class]] && [(TUITableOutlineView *)table sectionIsOpened:section] ) {
        switch (section) {
            case 0:     return 10;
            case 1:     return 4;
            case 3:     return 20;
            default:    return 5;
        }
    }
    return 1;
}

- (CGFloat)tableView:(TUITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == 0) {
        return 60.0;
    } else {
        return 30.0;
    }
}

- (TUIView *)tableView:(TUITableView *)tableView headerViewForSection:(NSInteger)section {
    return nil;
	ExampleSectionHeaderView *header = [[ExampleSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, 100, 32)];
	TUIAttributedString *title = [TUIAttributedString stringWithString:[NSString stringWithFormat:@"Example Section %d", (int)section]];
	title.color = [NSColor blackColor];
	title.font = [NSFont fontWithName:@"HelveticaNeue-Bold" size:15];
	header.labelRenderer.attributedString = title;
	
	// Dragging a title can drag the window too.
	[header setMoveWindowByDragging:YES];
	
	// Add an activity indicator to the header view with a 24x24 size.
	// Since we know the height of the header won't change we can pre-
	// pad it to 4. However, since the table view's width can change,
	// we'll create a layout constraint to keep the activity indicator
	// anchored 16px left of the right side of the header view.
	TUIActivityIndicatorView *indicator = [[TUIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 4, 24, 24)
																   activityIndicatorStyle:TUIActivityIndicatorViewStyleGray];
	[indicator addLayoutConstraint:[TUILayoutConstraint constraintWithAttribute:TUILayoutConstraintAttributeMaxX
																	 relativeTo:@"superview"
																	  attribute:TUILayoutConstraintAttributeMaxX
																		 offset:-16.0f]];
	
	// Add a simple embossing shadow to the white activity indicator.
	// This way, we can see it better on a bright background. Using
	// the standard layer property keeps the shadow stable through
	// animations.
	indicator.layer.shadowColor = [NSColor whiteColor].tui_CGColor;
	indicator.layer.shadowOffset = CGSizeMake(0, -1);
	indicator.layer.shadowOpacity = 1.0f;
	indicator.layer.shadowRadius = 1.0f;
    indicator.layoutName = @"indicator";
	
	// We then add it as a subview and tell it to start animating.
	[header	addSubview:indicator];
//	[indicator startAnimating];

	TUIButton *displayButton = [TUIButton buttonWithType:TUIButtonTypeTextured];
    displayButton.imageEdgeInsets = TUIEdgeInsetsMake(0, 0, 0, 1);
    [displayButton setImage:[NSImage imageNamed:NSImageNameQuickLookTemplate] forState:TUIControlStateNormal];
    displayButton.frame = CGRectMake(0, 4, 24, 24);
    [displayButton addLayoutConstraint:[TUILayoutConstraint constraintWithAttribute:TUILayoutConstraintAttributeMaxX relativeTo:@"indicator"
                                                                          attribute:TUILayoutConstraintAttributeMinX offset:-8]];
    
    [displayButton addActionForControlEvents:TUIControlEventMouseUpInside block:^{
        [[self tableView] toggleSection:section animated:YES];
        return;
        
        [TUIView beginAnimations:nil context:nil];
        [[self tableView] scrollToSection:section];
        [TUIView commitAnimations];
        return;
        
    }];
    
	[header addSubview:displayButton];

	return header;
}

- (TUITableViewCell *)tableView:(TUITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ExampleTableViewCell *cell = reusableTableCellOfClass(tableView, ExampleTableViewCell);
	
	TUIAttributedString *s = [TUIAttributedString stringWithString:[NSString stringWithFormat:@"example cell %d/%d", (int)indexPath.section, (int)indexPath.row]];
	s.color = [NSColor grayColor];
	s.font = [NSFont fontWithName:@"HelveticaNeue" size:15];;
	[s setFont:[NSFont fontWithName:@"HelveticaNeue-Bold" size:15] inRange:NSMakeRange(8, 4)]; // make the word "cell" bold
    
	cell.attributedString = s;
	
	return cell;
}
- (void)tableView:(TUITableOutlineView *)tableView willDisplayCell:(ExampleTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        cell.backgroundColor = [NSColor yellowColor];
    } else {
        cell.backgroundColor = [NSColor greenColor];
    }
       NSLog(@"table: %@", tableView
             );
    if ([tableView isKindOfClass:[TUITableOutlineView class]] &&  [tableView sectionIsOpened:indexPath.section]) {
        cell.backgroundView = tableView.openedSectionBackgroundView;
        cell.drawBackground = ^(TUIView *v, CGRect r)
        {
            [TUIGraphicsGetImageForView(tableView.openedSectionBackgroundView) drawInRect:r
                                                                                 fromRect:[tableView convertRect:v.frame toView:tableView.openedSectionBackgroundView]
                                                                                operation:NSCompositeSourceOver
                                                                                 fraction:1.0];
            
        };
        
        return;
    }
    
    cell.backgroundView = nil;;
    cell.drawBackground = nil;
}

- (void)tableView:(TUITableView *)tableView didClickRowAtIndexPath:(NSIndexPath *)indexPath withEvent:(NSEvent *)event {
    if (indexPath.row == 0) {
        [(TUITableOutlineView *)tableView toggleSection:indexPath.section animated:YES];
    } else
	if([event clickCount] == 1) {
		// do something cool
//        if ([self.navigationController.viewControllers count] > 1) {
//            [self.navigationController popToRootViewControllerAnimated:YES];
//        } else {
//            ExampleTableViewController *pushed = [[ExampleTableViewController alloc] initWithNibName:nil bundle:nil];
//            [self.navigationController pushViewController:pushed animated:YES];
//        }
	}
	
	if(event.type == NSRightMouseUp) {
		// show context menu
	}
}

-(BOOL)tableView:(TUITableView *)tableView performKeyActionWithEvent:(NSEvent *)event {
    NSLog(@"Key down event %@", event);
    return YES;
}

- (BOOL)tableView:(TUITableView *)tableView shouldSelectRowAtIndexPath:(NSIndexPath *)indexPath forEvent:(NSEvent *)event{
	switch (event.type) {
		case NSRightMouseDown:
			return NO;
	}
	
	return YES;
}

- (BOOL)tableView:(TUITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	// return YES to enable row reordering by dragging; don't implement this method or return
	// NO to disable
	return YES;
}

- (void)tableView:(TUITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	// update the model to reflect the changed index paths; since this example isn't backed by
	// a "real" model, after dropping a cell the table will revert to it's previous state
	NSLog(@"Move dragged row: %@ => %@", fromIndexPath, toIndexPath);
}

- (void)tableView:(TUITableView *)tableView moveRows:(NSArray *)arrayOfIdexes toIndexPath:(NSIndexPath *)toIndexPath
{
	NSLog(@"MULTI : Move dragged row: %@ => %@", arrayOfIdexes, toIndexPath);
    
}

-(NSIndexPath *)tableView:(TUITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)fromPath toProposedIndexPath:(NSIndexPath *)proposedPath {
	// optionally revise the drag-to-reorder drop target index path by returning a different index path
	// than proposedPath.  if proposedPath is suitable, return that.  if this method is not implemented,
	// proposedPath is used by default.
	return proposedPath;
}

@end
