//
//  MasterViewController.m
//  NSFetchResultsController111
//
//  Created by Pawel Ropa on 07/04/16.
//  Copyright © 2016 Pawel Ropa. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"

NSString* const kDidSeedDatabase = @"kDidSeedDatabase";

@interface MasterViewController ()

@end

@implementation MasterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    self.detailViewController = (DetailViewController*)[[self.splitViewController.viewControllers lastObject] topViewController];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDidSeedDatabase] == NO) {

        NSManagedObjectContext* context = [self.fetchedResultsController managedObjectContext];

        // Seeding db
        for (NSUInteger i = 0; i < 10000; i++) {
            NSLog(@"i : %lu", (unsigned long)i);
            [self insertNewObjectNumber:i];

            if (i % 100 == 0) {
                NSError* error = nil;
                if (![context save:&error]) {
                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                    abort();
                }
            }
        }

        // Save the context.
        NSError* error = nil;
        if (![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        NSLog(@"Finished seeding database");

        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDidSeedDatabase];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObjectNumber:(NSUInteger)number
{
    NSManagedObjectContext* context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription* entity = [[self.fetchedResultsController fetchRequest] entity];
    NSManagedObject* newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name]
                                                                      inManagedObjectContext:context];

    NSString* name = [NSString stringWithFormat:@"Contact %lu", (unsigned long)number];

    [newManagedObject setValue:name forKey:@"name"];

    // Save the context.
    NSError* error = nil;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath* indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject* object =
            [[self fetchedResultsController] objectAtIndexPath:indexPath];
        DetailViewController* controller = (DetailViewController*)[
            [segue destinationViewController] topViewController];
        [controller setDetailItem:object];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"
                                                            forIndexPath:indexPath];
    NSManagedObject* object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    [self configureCell:cell withObject:object];
    return cell;
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext* context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];

        NSError* error = nil;
        if (![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (void)configureCell:(UITableViewCell*)cell
           withObject:(NSManagedObject*)object
{
    cell.textLabel.text = [[object valueForKey:@"name"] description];
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController*)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"Contact" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];

    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];

    // Edit the sort key as appropriate.
    NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];

    [fetchRequest setSortDescriptors:@[ sortDescriptor ]];

    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController* aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                managedObjectContext:self.managedObjectContext
                                                                                                  sectionNameKeyPath:nil
                                                                                                           cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;

    NSError* error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController*)controller
  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type) {
    case NSFetchedResultsChangeInsert:
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                      withRowAnimation:UITableViewRowAnimationFade];
        break;

    case NSFetchedResultsChangeDelete:
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                      withRowAnimation:UITableViewRowAnimationFade];
        break;

    default:
        return;
    }
}

- (void)controller:(NSFetchedResultsController*)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath*)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath*)newIndexPath
{
    UITableView* tableView = self.tableView;

    switch (type) {
    case NSFetchedResultsChangeInsert:
        [tableView insertRowsAtIndexPaths:@[ newIndexPath ]
                         withRowAnimation:UITableViewRowAnimationFade];
        break;

    case NSFetchedResultsChangeDelete:
        [tableView deleteRowsAtIndexPaths:@[ indexPath ]
                         withRowAnimation:UITableViewRowAnimationFade];
        break;

    case NSFetchedResultsChangeUpdate:
        [self configureCell:[tableView cellForRowAtIndexPath:indexPath]
                 withObject:anObject];
        break;

    case NSFetchedResultsChangeMove:
        [tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
        break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller
{
    [self.tableView endUpdates];
}

@end
