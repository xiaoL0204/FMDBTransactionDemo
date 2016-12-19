//
//  ViewController.m
//  FMDBTransactionDemo
//
//  Created by xiaoL on 16/12/19.
//  Copyright © 2016年 xiaolin. All rights reserved.
//

#import "XLViewController.h"
#import "XLDBHandler.h"

@interface XLViewController ()

@end

@implementation XLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [XLDBHandler sharedInstance];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
