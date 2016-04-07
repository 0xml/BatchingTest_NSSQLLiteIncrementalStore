//
//  DetailViewController.h
//  NSFetchResultsController111
//
//  Created by Pawel Ropa on 07/04/16.
//  Copyright © 2016 Pawel Ropa. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

