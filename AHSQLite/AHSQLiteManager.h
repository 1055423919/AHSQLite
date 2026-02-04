//
//  AHSQLiteManager.h
//  AHSQLite
//
//  Created by Lxhong on 2026/2/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AHSQLiteManager : NSObject
@property (nonatomic, assign) sqlite3 *db;
@property (nonatomic, assign) BOOL debugSQL; // 是否打印 SQL 调试信息
+ (instancetype)shared;

/// 执行增删改 SQL
- (BOOL)executeSQL:(NSString *)sql;

/// 查询 SQL 返回字典数组
- (NSArray<NSDictionary *> *)querySQL:(NSString *)sql;

/// 批量插入对象数组到表
- (BOOL)executeBatchSQL:(NSArray<NSString *> *)sqls;
@end

NS_ASSUME_NONNULL_END
