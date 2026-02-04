Pod::Spec.new do |s|
  s.name             = 'AHSQLite'
  s.version          = '1.0.0'
  s.summary          = '轻量级 Objective-C SQLite ORM 框架'

  s.description      = <<-DESC
AHSQLite 是一个轻量级 Objective-C SQLite ORM 框架，提供自动建表、增删改查、批量操作等功能。
使用简单，支持直接在模型对象上保存和查询数据。
  DESC

  s.homepage         = 'https://github.com/1055423919/AHSQLite'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Lxhong' => 'h1055423919@gmail.com' }
  s.source           = { :git => 'https://github.com/1055423919/AHSQLite.git', :tag => s.version.to_s }

  s.platform         = :ios, '11.0'
  s.requires_arc     = true

  # 所有源代码文件
  s.source_files     = 'AHSQLite/**/*.{h,m}'
  s.public_header_files = 'AHSQLite/**/*.h'

  # 依赖的系统库
  s.frameworks       = 'Foundation'
  s.libraries  = 'sqlite3'      # sqlite3 写在 libraries
  # 可选，允许警告（调试用）
  #s.allow_warnings   = true
end

