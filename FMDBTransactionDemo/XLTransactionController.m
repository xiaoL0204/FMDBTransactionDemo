//
//  XLTransactionController.m
//  FMDBTransactionDemo
//
//  Created by xiaoL on 16/12/19.
//  Copyright © 2016年 xiaolin. All rights reserved.
//

#import "XLTransactionController.h"
#import "XLDBHandler.h"

@interface XLTransactionController ()

@end

@implementation XLTransactionController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[XLDBHandler sharedInstance] saveLargeHotelBrowseRecordWithTransaction];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
