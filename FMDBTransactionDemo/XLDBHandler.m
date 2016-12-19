//
//  XLDBHandler.m
//  FMDBTransactionDemo
//
//  Created by xiaoL on 16/12/19.
//  Copyright © 2016年 xiaolin. All rights reserved.
//

#import "XLDBHandler.h"

#define kHotelBrowseRecordCountMax 1000    //历史记录存储最大数量


@interface XLDBHandler()
@property (nonatomic,strong) FMDatabase *db;
@property (nonatomic,strong) FMDatabaseQueue *dbQueue;
@end

static NSString *db_name = @"FMDBTransactionDemo.db";

//数据库信息
static NSString *createTB_db_info = @"create table if not exists t_dbInfo(c_value text,c_key text)";
//浏览记录
static NSString *createTB_browse_record = @"create table if not exists t_hotel_history(name text,id integer,browsetime long)";



@implementation XLDBHandler


SINGLETON_IMPLEMENT(XLDBHandler)


-(id)init{
    self = [super init];
    if (self) {
        int dbVersion = 0;
        //open database
        [self openDB];
        //check the version
        NSString *version = [self getDBInfoValueWithKey:@"db_version"];
        dbVersion = version?[version intValue]:0;
        //update the database,then update version
        switch (dbVersion) {
            case 0:
                //创建表
                [self.db executeUpdate:createTB_browse_record];
                [self.db executeUpdate:createTB_db_info];
                [self insertDBInfoValueWithKey:@"1" key:@"db_version"];
            case 1:
                //数据库加字段
                if (![self.db columnExists: @"address" inTableWithName:@"t_hotel_history"])
                    [self.db executeUpdate:@"ALTER TABLE t_hotel_history ADD address text"];
                [self setDBInfoValueWithKey:@"2" key:@"db_version"];
            case 2:
                
            default:
                break;
        }
    }
    return self;
}




-(NSString*)getDBInfoValueWithKey:(NSString*)Key{
    return  [self.db stringForQuery:@"SELECT c_value FROM t_dbInfo WHERE c_key = ?", Key];
}
-(void)insertDBInfoValueWithKey:(NSString*)value key:(NSString*)key{
    [self.db executeUpdate:@"INSERT INTO t_dbInfo(c_key, c_value) VALUES(?,?)", key, value];
}
-(void)setDBInfoValueWithKey:(NSString*)value key:(NSString*)key{
    [self.db executeUpdate:@"UPDATE t_dbInfo set c_value =? WHERE c_key =? ", value, key];
}





//保存大量数据，使用事务
-(void)saveLargeHotelBrowseRecordWithTransaction{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"使用事务，开始插入数据...");
        NSDate *startDate = [NSDate date];
        NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
        [self.db beginTransaction];
        BOOL isRollback = NO;
        @try {
            for (int i=0; i<kDataCountNum; i++) {
                NSString *name = [NSString stringWithFormat:@"李四%@",@(i)];
                NSInteger sId = i;
                NSString *address = [NSString stringWithFormat:@"adress%@",@(i)];
                
                BOOL result = [self.db executeUpdate:@"INSERT INTO t_hotel_history(name,id,address,browsetime) VALUES(?,?,?,?)",name?name:@"",@(sId),address?address:@"",@(timestamp)];
                
                
                //使用打印会耗费很多时间
                //                if (!result) {
                //                    NSLog(@"插入失败");
                //                }else{
                //                    NSLog(@"插入数据成功！  index:%@",@(i));
                //                }
            }
        } @catch (NSException *exception) {
            isRollback = YES;
            [self.db rollback];
        } @finally {
            if (!isRollback) {
                [self.db commit];
            }else{
                [self.db close];
            }
        }
        
        
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:startDate];
        NSLog(@"使用事务，插入%@条数据用时%@秒",@(kDataCountNum),@(timeInterval));
    });
}

//保存大量数据，不使用事务
-(void)saveLargeHotelBrowseRecordNoTransaction{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"不使用事务，开始插入数据...");
        NSDate *startDate = [NSDate date];
        NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
        for (int i=0; i<kDataCountNum; i++) {
            NSString *name = [NSString stringWithFormat:@"李四%@",@(i)];
            NSInteger sId = i;
            NSString *address = [NSString stringWithFormat:@"adress%@",@(i)];
            
            BOOL result = [self.db executeUpdate:@"INSERT INTO t_hotel_history(name,id,address,browsetime) VALUES(?,?,?,?)",name?name:@"",@(sId),address?address:@"",@(timestamp)];
            
            
            //        使用打印会耗费很多时间
            //                        if (!result) {
            //                            NSLog(@"插入失败");
            //                        }else{
            //                            NSLog(@"插入数据成功！  index:%@",@(i));
            //                        }
        }
        
        NSDate *endDate = [NSDate date];
        NSTimeInterval timeInterval = [endDate timeIntervalSinceDate:startDate];
        NSLog(@"不使用事务，插入%@条数据用时%@秒",@(kDataCountNum),@(timeInterval));
    });
}

























#pragma mark - save browse record
-(void)saveHotelBrowseRecordWithTransaction:(NSString *)name id:(NSInteger)sId address:(NSString *)address{
    if (name) {
        //the count of hotel history existed
        NSInteger recordCount = [self.db intForQuery:@"SELECT COUNT(*) FROM t_hotel_history"];
        NSInteger timeInterval = [[NSDate date] timeIntervalSince1970];
        FMResultSet *selectSet = [self.db executeQuery:@"SELECT * FROM t_hotel_history WHERE id=?",@(sId)];
        if ([selectSet next]) {    //record exists，update it
            [self updateHotelBrowseRecordWithTransaction:name id:sId address:address timestamp:timeInterval];
        }else{      //record not exist
            if (recordCount > kHotelBrowseRecordCountMax-1) {    //count of records is larger than limit,first delete the earliest record
                [self.db executeUpdate:@"DELETE FROM t_hotel_history WHERE browsetime IN (SELECT browsetime FROM t_hotel_history ORDER BY browsetime LIMIT 0,1)"];
            }
            //then insert a new one
            [self insertHotelBrowseRecordWithTransaction:name id:sId address:address timestamp:timeInterval];
        }
    }
}

//update an exist browse record
-(void)updateHotelBrowseRecordWithTransaction:(NSString *)name id:(NSInteger)sId address:(NSString *)address timestamp:(long)timestamp{
    [self.db beginTransaction];
    BOOL isRollback = NO;
    @try {
        [self.db executeUpdate:@"UPDATE t_hotel_history set name=?,address=?,browsetime=? WHERE hotelid=?",name?name:@"",address?address:@"",@(timestamp),@(sId)];
    } @catch (NSException *exception) {
        isRollback = YES;
        [self.db rollback];
    } @finally {
        if (!isRollback) [self.db commit];
    }
}
//insert a new browse record
-(void)insertHotelBrowseRecordWithTransaction:(NSString *)name id:(NSInteger)sId address:(NSString *)address timestamp:(long)timestamp{
    [self.db beginTransaction];
    BOOL isRollback = NO;
    @try {
        [self.db executeUpdate:@"INSERT INTO t_hotel_history(name,id,address,browsetime) VALUES(?,?,?,?)",name?name:@"",@(sId),address?address:@"",@(timestamp)];
    } @catch (NSException *exception) {
        isRollback = YES;
        [self.db rollback];
    } @finally {
        if (!isRollback) [self.db commit];
    }
}









#pragma mark - open database
- (void)openDB{
    self.db = [FMDatabase databaseWithPath:[self getFilePath]];
    self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:[self getFilePath]];
    NSLog(@"db file path:%@",[self getFilePath]);
    if(![self.db open]){
        NSLog(@"数据库打开失败...");
    }
}
#pragma mark - remove database
- (void)deleteDatabse{
    BOOL success = NO;
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[self getFilePath]]){
        [self.db close];
        success = [fileManager removeItemAtPath:[self getFilePath] error:&error];
    }
}
#pragma mark - drop a table
- (BOOL)deleteTable:(NSString *)tableName{
    NSString *sqlstr = [NSString stringWithFormat:@"DROP TABLE %@", tableName];
    if (![self.db executeUpdate:sqlstr]){
        return NO;
    }
    
    return YES;
}
#pragma mark - erase a table
- (BOOL)eraseTable:(NSString *)tableName{
    NSString *sqlstr = [NSString stringWithFormat:@"DELETE FROM %@", tableName];
    if (![self.db executeUpdate:sqlstr]){
        return NO;
    }
    
    return YES;
}
#pragma mark - database's file path
- (NSString*)getFilePath{
    NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *databaseFilePath = [[documentsPaths objectAtIndex:0] stringByAppendingPathComponent:db_name];
    return databaseFilePath;
}
#pragma mark -
@end
