//
//  AHSQLite.m
//  AHSQLite
//
//  Created by Lxhong on 2026/2/4.
//

#import "AHSQLite.h"
#import <sqlite3.h>
#import <objc/runtime.h>

@implementation AHSQLiteManager
+ (instancetype)shared {
    static AHSQLiteManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[AHSQLiteManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject
                          stringByAppendingPathComponent:@"bg_sqlite.db"];
        if (sqlite3_open(path.UTF8String, &_db) != SQLITE_OK) {
            NSLog(@"SQLite open failed");
        }
    }
    return self;
}

- (BOOL)executeSQL:(NSString *)sql {
    char *err;
    if (sqlite3_exec(_db, sql.UTF8String, NULL, NULL, &err) != SQLITE_OK) {
        NSLog(@"SQLite execute failed: %s", err);
        return NO;
    }
    return YES;
}

- (NSArray<NSDictionary *> *)querySQL:(NSString *)sql {
    NSMutableArray *result = [NSMutableArray array];
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(_db, sql.UTF8String, -1, &stmt, NULL) == SQLITE_OK) {
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            NSMutableDictionary *row = [NSMutableDictionary dictionary];
            int count = sqlite3_column_count(stmt);
            for (int i=0; i<count; i++) {
                const char *name = sqlite3_column_name(stmt, i);
                const char *value = (const char *)sqlite3_column_text(stmt, i);
                if (value) row[@(name)] = [NSString stringWithUTF8String:value];
                else row[@(name)] = @"";
            }
            [result addObject:row];
        }
    }
    sqlite3_finalize(stmt);
    return result;
}
/// 批量执行 SQL（事务）
- (BOOL)executeBatchSQL:(NSArray<NSString *> *)sqls {
    char *err;
    if (sqlite3_exec(_db, "BEGIN TRANSACTION", NULL, NULL, &err) != SQLITE_OK) {
        NSLog(@"Begin transaction failed: %s", err);
        return NO;
    }
    for (NSString *sql in sqls) {
        if (self.debugSQL) NSLog(@"[SQL BATCH] %@", sql);
        if (sqlite3_exec(_db, sql.UTF8String, NULL, NULL, &err) != SQLITE_OK) {
            NSLog(@"Batch SQL failed: %s", err);
            sqlite3_exec(_db, "ROLLBACK", NULL, NULL, NULL);
            return NO;
        }
    }
    if (sqlite3_exec(_db, "COMMIT", NULL, NULL, &err) != SQLITE_OK) {
        NSLog(@"Commit transaction failed: %s", err);
        return NO;
    }
    return YES;
}
- (BOOL)cleanTable:(NSString *)tableName {
    if (tableName.length == 0) return NO;

    NSString *sql =
    [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", tableName];

    char *errmsg = NULL;
    int result = sqlite3_exec(self.db, sql.UTF8String, NULL, NULL, &errmsg);

    if (result != SQLITE_OK) {
        if (errmsg) {
            NSLog(@" cleanTable error: %s", errmsg);
            sqlite3_free(errmsg);
        }
        return NO;
    }

    NSLog(@" from: %@ clean and delete", tableName);
    return YES;
}
@end

@implementation NSObject (AHSQLiteAuto)
#pragma mark - 获取字段字典
/// 获取 Model 所有属性及对应 SQLite 类型
/// @param cls 目标类
/// @return NSDictionary<NSString *, NSString *> key=属性名 value=字段类型
/// @discussion 内部使用 Runtime 遍历属性自动生成 SQLite 字段类型
+ (NSDictionary<NSString *, NSString *> *)bg_columnInfoForClass:(Class)cls {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    unsigned int count = 0;
    objc_property_t *props = class_copyPropertyList(cls, &count);
    for (int i=0; i<count; i++) {
        objc_property_t prop = props[i];
        const char *name = property_getName(prop);
        const char *attr = property_getAttributes(prop);
        NSString *key = [NSString stringWithUTF8String:name];
        NSString *type = @"TEXT"; // 默认类型
        
        NSString *attrStr = [NSString stringWithUTF8String:attr];
        if ([attrStr hasPrefix:@"T@\"NSString\""]) type = @"TEXT";
        else if ([attrStr hasPrefix:@"Ti"] || [attrStr hasPrefix:@"Tq"] || [attrStr hasPrefix:@"Ts"] || [attrStr hasPrefix:@"TB"]) type = @"INTEGER";
        else if ([attrStr hasPrefix:@"Tf"] || [attrStr hasPrefix:@"Td"]) type = @"REAL";
        else if ([attrStr hasPrefix:@"T@\"NSData\""]) type = @"BLOB";
        
        dict[key] = type;
    }
    free(props);
    return dict;
}

#pragma mark - 创建表
/// 创建表（如果不存在则创建）
/// @param tableName 表名
/// @return BOOL 是否成功
/// @discussion 内部调用，第一次保存或查询时会自动建表
+ (BOOL)bg_createTableIfNotExists:(NSString *)tableName {
    NSDictionary *columns = [self bg_columnInfoForClass:self];
    NSMutableArray *colDefs = [NSMutableArray array];
    [columns enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *type, BOOL * _Nonnull stop) {
        [colDefs addObject:[NSString stringWithFormat:@"%@ %@", key, type]];
    }];
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@)", tableName, [colDefs componentsJoinedByString:@", "]];
    return [[AHSQLiteManager shared] executeSQL:sql];
}

#pragma mark - Save
/// 保存对象到表
/// @param tableName 表名
/// @return BOOL 是否保存成功
/// @discussion 使用示例:
/// TTListInfoModel *model = [[TTListInfoModel alloc] init];
/// model.identifer = @"001";
/// model.content = @"测试内容";
/// [model sql_save:@"TimeTunnelList"];
- (BOOL)sql_save:(NSString *)tableName {
    [[self class] bg_createTableIfNotExists:tableName];
    
    NSMutableArray *keys = [NSMutableArray array];
    NSMutableArray *values = [NSMutableArray array];
    
    unsigned int count = 0;
    objc_property_t *props = class_copyPropertyList([self class], &count);
    for (int i=0; i<count; i++) {
        NSString *key = [NSString stringWithUTF8String:property_getName(props[i])];
        id value = [self valueForKey:key] ?: @"";
        [keys addObject:key];
        [values addObject:[NSString stringWithFormat:@"'%@'", value]];
    }
    free(props);
    
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", tableName, [keys componentsJoinedByString:@","], [values componentsJoinedByString:@","]];
    return [[AHSQLiteManager shared] executeSQL:sql];
}

#pragma mark - Find All
/// 查询表里所有数据
/// @param tableName 表名
/// @return NSArray<NSObject *> 返回对象数组
/// @discussion 使用示例:
/// NSArray *all = [TTListInfoModel sql_findAll:@"TimeTunnelList"];
+ (NSArray *)sql_findAll:(NSString *)tableName {
    [self bg_createTableIfNotExists:tableName];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@", tableName];
    NSArray *rows = [[AHSQLiteManager shared] querySQL:sql];
    
    NSMutableArray *models = [NSMutableArray array];
    for (NSDictionary *dict in rows) {
        id obj = [[self alloc] init];
        [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *objValue, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:NSSelectorFromString(key)]) {
                [obj setValue:objValue forKey:key];
            }
        }];
        [models addObject:obj];
    }
    return models;
}

#pragma mark - Find by key/value
/// 按 key/value 查询数据
/// @param tableName 表名
/// @param key 字段名
/// @param value 字段值
/// @return NSArray<NSObject *> 返回匹配对象数组
/// @discussion 使用示例:
/// NSArray *some = [TTListInfoModel sql_find:@"TimeTunnelList" key:@"identifer" value:@"001"];
+ (NSArray *)sql_find:(NSString *)tableName key:(NSString *)key value:(NSString *)value {
    NSString *where = [NSString stringWithFormat:@"%@='%@'", key, value];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@", tableName, where];
    NSArray *rows = [[AHSQLiteManager shared] querySQL:sql];
    
    NSMutableArray *models = [NSMutableArray array];
    for (NSDictionary *dict in rows) {
        id obj = [[self alloc] init];
        [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *objValue, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:NSSelectorFromString(key)]) {
                [obj setValue:objValue forKey:key];
            }
        }];
        [models addObject:obj];
    }
    return models;
}

#pragma mark - Delete
/// 按条件删除表里数据
/// @param tableName 表名
/// @param key 字段名
/// @param value 字段值
/// @return BOOL 是否删除成功
/// @discussion 使用示例:
/// [TTListInfoModel sql_delete:@"TimeTunnelList" key:@"identifer" value:@"001"];
+ (BOOL)sql_delete:(NSString *)tableName key:(NSString *)key value:(NSString *)value {
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@='%@'", tableName, key, value];
    return [[AHSQLiteManager shared] executeSQL:sql];
}

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
+ (BOOL)sql_update:(NSString *)tableName model:(NSObject *)model key:(NSString *)key value:(NSString *)value {
    NSMutableArray *sets = [NSMutableArray array];
    unsigned int count = 0;
    objc_property_t *props = class_copyPropertyList([model class], &count);
    for (int i=0; i<count; i++) {
        NSString *propName = [NSString stringWithUTF8String:property_getName(props[i])];
        id val = [model valueForKey:propName] ?: @"";
        [sets addObject:[NSString stringWithFormat:@"%@='%@'", propName, val]];
    }
    free(props);
    
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@='%@'", tableName, [sets componentsJoinedByString:@","], key, value];
    return [[AHSQLiteManager shared] executeSQL:sql];
}

#pragma mark -- 批量
/// 批量插入对象数组到表（事务）
/// @param tableName 表名
/// @param models 对象数组
/// @return BOOL 是否成功
/// @discussion 使用示例:
/// NSArray *arr = @[model1, model2, model3];
/// [TTListInfoModel sql_saveBatch:@"TimeTunnelList" models:arr];
+ (BOOL)sql_saveBatch:(NSString *)tableName models:(NSArray<NSObject *> *)models {
    if (models.count == 0) return YES;
    [self bg_createTableIfNotExists:tableName];
    
    NSMutableArray *sqls = [NSMutableArray array];
    for (NSObject *model in models) {
        NSMutableArray *keys = [NSMutableArray array];
        NSMutableArray *values = [NSMutableArray array];
        unsigned int count = 0;
        objc_property_t *props = class_copyPropertyList([model class], &count);
        for (int i=0; i<count; i++) {
            NSString *key = [NSString stringWithUTF8String:property_getName(props[i])];
            id value = [model valueForKey:key] ?: @"";
            [keys addObject:key];
            [values addObject:[NSString stringWithFormat:@"'%@'", value]];
        }
        free(props);
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", tableName, [keys componentsJoinedByString:@","], [values componentsJoinedByString:@","]];
        [sqls addObject:sql];
    }
    
    return [[AHSQLiteManager shared] executeBatchSQL:sqls];
}

#pragma mark --清除全部表数据
+ (BOOL)sql_cleanAll:(NSString *)tableName {
    return [[AHSQLiteManager shared] cleanTable:tableName];
}
@end
