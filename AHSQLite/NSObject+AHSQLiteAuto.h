//
//  NSObject+AHSQLiteAuto.h
//  AHSQLite
//
//  Created by Lxhong on 2026/2/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (AHSQLiteAuto)

#pragma mark - Save
/// 保存对象到表
/// @param tableName 表名
/// @return BOOL 是否保存成功
/// @discussion 使用示例:
/// TTListInfoModel *model = [[TTListInfoModel alloc] init];
/// model.identifer = @"001";
/// model.content = @"测试内容";
/// [model sql_save:@"TimeTunnelList"];
- (BOOL)sql_save:(NSString *)tableName;

#pragma mark - Find
/// 查询表里所有数据
/// @param tableName 表名
/// @return NSArray<NSObject *> 返回对象数组
/// @discussion 使用示例:
/// NSArray *all = [TTListInfoModel sql_findAll:@"TimeTunnelList"];
+ (NSArray *)sql_findAll:(NSString *)tableName;

/// 按 key/value 查询数据
/// @param tableName 表名
/// @param key 字段名
/// @param value 字段值
/// @return NSArray<NSObject *> 返回匹配对象数组
/// @discussion 使用示例:
/// NSArray *some = [TTListInfoModel sql_find:@"TimeTunnelList" key:@"identifer" value:@"001"];
+ (NSArray *)sql_find:(NSString *)tableName key:(NSString *)key value:(NSString *)value;

#pragma mark - Delete
/// 按条件删除表里数据
/// @param tableName 表名
/// @param key 字段名
/// @param value 字段值
/// @return BOOL 是否删除成功
/// @discussion 使用示例:
/// [TTListInfoModel sql_delete:@"TimeTunnelList" key:@"identifer" value:@"001"];
+ (BOOL)sql_delete:(NSString *)tableName key:(NSString *)key value:(NSString *)value;

#pragma mark - Update
/// 按 key/value 更新表里数据
/// @param tableName 表名
/// @param model 更新后的对象
/// @param key 条件字段名
/// @param value 条件字段值
/// @return BOOL 是否更新成功
/// @discussion 使用示例:
/// TTListInfoModel *model = [[TTListInfoModel alloc] init];
/// model.content = @"修改后的内容";
/// [TTListInfoModel sql_update:@"TimeTunnelList" model:model key:@"identifer" value:@"001"];
+ (BOOL)sql_update:(NSString *)tableName model:(NSObject *)model key:(NSString *)key value:(NSString *)value;

#pragma mark -- 批量插入方法
/// 批量插入对象数组到表（事务）
/// @param tableName 表名
/// @param models 对象数组
/// @return BOOL 是否成功
/// @discussion 使用示例:
/// NSArray *arr = @[model1, model2, model3];
/// [TTListInfoModel sql_saveBatch:@"TimeTunnelList" models:arr];
+ (BOOL)sql_saveBatch:(NSString *)tableName models:(NSArray<NSObject *> *)models;

#pragma mark --清除全部表数据
/// 清空并删除表（只需表名）
+ (BOOL)sql_cleanAll:(NSString *)tableName;
@end

NS_ASSUME_NONNULL_END
