//
//  XLDBHandler.h
//  FMDBTransactionDemo
//
//  Created by xiaoL on 16/12/19.
//  Copyright © 2016年 xiaolin. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDataCountNum 10000

@interface XLDBHandler : NSObject
SINGLETON_DEFINE(XLDBHandler)


//保存大量数据，使用事务
-(void)saveLargeHotelBrowseRecordWithTransaction;
//保存大量数据，不使用事务
-(void)saveLargeHotelBrowseRecordNoTransaction;

@end
