# 萤 - 功能增强计划

## 📋 概述

基于对市场上主流倒数日应用的全面分析（Days Matter、TheDayBefore、Countdown Widget、DaysTill等），本文档规划了功能增强路线图，旨在将"萤"打造成功能最完善的倒数日应用。

## 🎯 核心功能对比

### 已有功能 ✅
- ✅ 倒计时/正计时支持
- ✅ 农历日期支持
- ✅ 桌面小部件（多尺寸）
- ✅ 日历视图
- ✅ 分享卡片（多模板）
- ✅ WebDAV云同步
- ✅ iCalendar导入导出
- ✅ 分类管理
- ✅ 事件归档
- ✅ 基础提醒通知
- ✅ 多实例小部件配置

### 待增强功能 📌

#### 🔔 高级提醒系统 (优先级: 高)
**竞争对手参考**: Days Matter, Countdown Widget

**功能清单**:
1. **多阶段智能提醒**
   - 提前 1天、3天、7天、30天、90天自动提醒
   - 当天多次提醒（早、中、晚）
   - 智能提醒时间（根据用户习惯）

2. **位置感知提醒**
   - 到达/离开某地点时提醒
   - 集成地理位置服务

3. **重复提醒模式**
   - 每周/每月固定时间提醒
   - 自定义重复规则

4. **提醒历史**
   - 查看已发送的提醒记录
   - 提醒统计

**实现难度**: 中等  
**所需依赖**: 
- `geolocator` - 位置服务
- `flutter_local_notifications` - 已集成
- 数据库扩展 - 存储提醒规则

**代码文件**:
- `lib/models/advanced_reminder.dart` (新建)
- `lib/services/notification_service.dart` (扩展)
- `lib/screens/settings/reminder_settings_screen.dart` (新建)

---

#### 📸 事件相册/故事功能 (优先级: 高)
**竞争对手参考**: TheDayBefore, DaysTill

**功能清单**:
1. **照片日志**
   - 为每个事件添加多张照片
   - 照片时间线展示
   - 照片备注和标签

2. **故事记录**
   - 类似日记功能
   - 文字+图片记录重要时刻
   - 时间轴视图

3. **回忆提醒**
   - "去年的今天"提醒
   - 历史照片回顾

**实现难度**: 中等  
**所需依赖**: 
- 已有 `image_picker`
- 需要 `photo_view` - 图片查看器
- 数据库扩展 - 存储照片和故事

**代码文件**:
- `lib/models/event_memory.dart` (新建)
- `lib/screens/memory_gallery_screen.dart` (新建)
- `lib/widgets/memory_card.dart` (新建)
- `lib/services/memory_service.dart` (新建)

---

#### 🔒 隐私与安全 (优先级: 高)
**竞争对手参考**: Days Matter, Countdown Widget

**功能清单**:
1. **生物识别锁**
   - 指纹/Face ID解锁
   - 应用启动时验证
   - 设置页进入验证

2. **隐藏事件**
   - 标记为私密的事件不在主列表显示
   - 需要验证才能查看
   - 私密事件不显示在小部件

3. **数据加密**
   - 敏感字段加密存储
   - 云同步数据加密
   - 本地数据库加密

**实现难度**: 中等  
**所需依赖**: 
- `local_auth` - 生物识别
- `flutter_secure_storage` - 已集成

**代码文件**:
- `lib/services/security_service.dart` (新建)
- `lib/screens/settings/security_settings_screen.dart` (新建)
- `lib/models/countdown_event.dart` (添加 `isPrivate` 字段)

---

#### 📱 锁屏小部件 (优先级: 高)
**竞争对手参考**: Days Matter, Countdown Widget

**功能清单**:
1. **Android 锁屏小部件**
   - Android 7.0+ 锁屏小部件支持
   - 显示最近倒数日
   - 快速查看模式

2. **小部件自定义**
   - 透明度调节
   - 主题色匹配
   - 信息密度选择

**实现难度**: 中等  
**所需依赖**: 
- 需要原生 Android 代码支持
- `home_widget` 已集成，需扩展

**代码文件**:
- `android/app/src/main/kotlin/.../LockScreenWidgetProvider.kt` (新建)
- `lib/services/widget_service.dart` (扩展)

---

#### 📊 进度可视化 (优先级: 中)
**竞争对手参考**: Countdown Widget, TheDayBefore

**功能清单**:
1. **进度环**
   - 圆形进度条显示
   - 自定义起始日期
   - 多种样式

2. **年度进度**
   - 年度天数网格
   - 已过天数标记
   - 事件高亮显示

3. **月度视图**
   - 月度进度条
   - 当月事件分布

**实现难度**: 简单  
**所需依赖**: 
- `percent_indicator` - 进度条
- 自定义绘制组件

**代码文件**:
- `lib/widgets/progress_ring.dart` (新建)
- `lib/widgets/year_progress_grid.dart` (新建)
- `lib/screens/progress_view_screen.dart` (新建)

---

#### ⏰ 高级时间单位 (优先级: 中)
**竞争对手参考**: Countdown Widget, DaysTill

**功能清单**:
1. **工作日倒数**
   - 排除周末和节假日
   - 自定义工作日
   - 节假日数据库

2. **自定义单位**
   - 周数显示
   - 月数显示
   - "心跳数"（趣味显示）
   - 自定义单位名称

3. **精确时间显示**
   - 时分秒精确显示
   - 多时区支持

**实现难度**: 简单  
**所需依赖**: 
- 无需额外依赖
- 需要节假日数据

**代码文件**:
- `lib/utils/time_calculator.dart` (新建)
- `lib/widgets/advanced_time_display.dart` (新建)
- `lib/data/holidays.json` (新建)

---

#### 📝 事件模板系统 (优先级: 中)
**竞争对手参考**: Days Matter, 小沙漏

**功能清单**:
1. **内置模板**
   - 生日模板（自动计算年龄）
   - 纪念日模板（恋爱、结婚）
   - 考试倒计时模板
   - 节日模板（自动农历转换）

2. **自定义模板**
   - 保存常用事件为模板
   - 模板分类管理
   - 快速创建

3. **智能建议**
   - 根据标题推荐图标
   - 根据日期类型推荐分类
   - 常用事件智能排序

**实现难度**: 简单  
**所需依赖**: 
- 无需额外依赖

**代码文件**:
- `lib/models/event_template.dart` (新建)
- `lib/services/template_service.dart` (新建)
- `lib/screens/template_gallery_screen.dart` (新建)
- `lib/data/default_templates.dart` (新建)

---

#### 📈 数据统计与分析 (优先级: 中)
**竞争对手参考**: 自研功能

**功能清单**:
1. **事件统计**
   - 事件总数统计
   - 分类分布图
   - 时间分布热力图

2. **时间分析**
   - 平均倒数天数
   - 事件密度分析
   - 最忙碌的月份

3. **使用报告**
   - 月度/年度报告
   - 数据可视化图表

**实现难度**: 中等  
**所需依赖**: 
- `fl_chart` - 图表库

**代码文件**:
- `lib/screens/statistics_screen.dart` (新建)
- `lib/services/analytics_service.dart` (新建)
- `lib/widgets/charts/` (新建目录)

---

#### 🔄 批量操作功能 (优先级: 中)
**竞争对手参考**: 通用功能

**功能清单**:
1. **批量编辑**
   - 批量修改分类
   - 批量调整提醒
   - 批量修改日期

2. **批量管理**
   - 批量删除
   - 批量归档
   - 批量导出

3. **快速操作**
   - 长按多选
   - 全选/反选
   - 拖拽排序

**实现难度**: 简单  
**所需依赖**: 
- 无需额外依赖

**代码文件**:
- `lib/screens/batch_edit_screen.dart` (新建)
- `lib/widgets/batch_operation_bar.dart` (新建)
- `lib/providers/events_provider.dart` (扩展)

---

#### 🎨 小部件增强 (优先级: 中)
**竞争对手参考**: Countdown Widget, TheDayBefore

**功能清单**:
1. **更多样式**
   - 卡片样式
   - 极简样式
   - 照片背景样式
   - 渐变样式

2. **自定义布局**
   - 信息项显示/隐藏
   - 字体大小调节
   - 颜色主题选择

3. **动态效果**
   - 倒计时动画
   - 进度动画
   - 点击动画

**实现难度**: 中等  
**所需依赖**: 
- 需要原生 Android 代码扩展

**代码文件**:
- `lib/models/widget_theme.dart` (新建)
- `android/app/src/main/res/layout/` (新增布局文件)
- `lib/services/widget_service.dart` (扩展)

---

#### 👥 共享事件功能 (优先级: 中)
**竞争对手参考**: DaysTill, 倒数鸭

**功能清单**:
1. **事件分享**
   - 生成分享链接
   - 邀请他人加入
   - 二维码分享

2. **协作功能**
   - 多人共同维护事件
   - 评论和留言
   - 通知所有参与者

3. **家庭账户**
   - 家庭共享日历
   - 成员管理
   - 权限控制

**实现难度**: 高  
**所需依赖**: 
- 后端服务（或使用 Firebase/Supabase）
- 需要用户系统

**代码文件**:
- `lib/services/share_service.dart` (新建)
- `lib/models/shared_event.dart` (新建)
- `lib/screens/shared_events_screen.dart` (新建)

---

#### 🤖 智能功能 (优先级: 低)
**竞争对手参考**: 新兴应用

**功能清单**:
1. **智能分类**
   - AI自动推荐分类
   - 图标智能匹配

2. **自然语言创建**
   - "下周三开会"自动解析
   - "每年农历三月初三"识别

3. **智能提醒**
   - 根据事件重要性调整提醒频率
   - 学习用户习惯

**实现难度**: 高  
**所需依赖**: 
- AI服务集成（可选本地模型）
- NLP库

**代码文件**:
- `lib/services/ai_service.dart` (新建)
- `lib/utils/nlp_parser.dart` (新建)

---

## 🚀 实施路线图

### 第一阶段 (1-2周) - 高优先级核心功能
1. ✅ 创建功能增强计划文档
2. 🔔 实现高级提醒系统
3. 📸 添加事件相册/故事功能
4. 🔒 添加隐私安全功能

### 第二阶段 (2-3周) - 用户体验提升
1. 📱 实现锁屏小部件
2. 📊 添加进度可视化
3. ⏰ 实现高级时间单位
4. 📝 实现事件模板系统

### 第三阶段 (1-2周) - 辅助功能
1. 📈 添加数据统计分析
2. 🔄 实现批量操作
3. 🎨 优化小部件系统

### 第四阶段 (可选) - 高级功能
1. 👥 实现共享事件功能
2. 🤖 添加智能功能

---

## 📊 技术架构调整

### 数据库扩展
```sql
-- 新增表：事件记忆/相册
CREATE TABLE event_memories (
  id TEXT PRIMARY KEY,
  event_id TEXT NOT NULL,
  type TEXT NOT NULL, -- 'photo', 'story', 'note'
  content TEXT,
  image_path TEXT,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (event_id) REFERENCES events(id)
);

-- 新增表：高级提醒规则
CREATE TABLE advanced_reminders (
  id TEXT PRIMARY KEY,
  event_id TEXT NOT NULL,
  type TEXT NOT NULL, -- 'multi_stage', 'location', 'recurring'
  config TEXT NOT NULL, -- JSON配置
  is_active INTEGER DEFAULT 1,
  FOREIGN KEY (event_id) REFERENCES events(id)
);

-- 新增表：事件模板
CREATE TABLE event_templates (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT,
  icon TEXT,
  default_values TEXT, -- JSON
  is_builtin INTEGER DEFAULT 0
);

-- 修改表：事件表扩展字段
ALTER TABLE events ADD COLUMN is_private INTEGER DEFAULT 0;
ALTER TABLE events ADD COLUMN workdays_only INTEGER DEFAULT 0;
ALTER TABLE events ADD COLUMN custom_unit TEXT;
```

### 新增依赖 (pubspec.yaml)
```yaml
dependencies:
  # 生物识别
  local_auth: ^2.1.8
  
  # 地理位置服务（位置提醒）
  geolocator: ^13.0.2
  geocoding: ^3.0.0
  
  # 图片查看器
  photo_view: ^0.15.0
  
  # 进度条
  percent_indicator: ^4.2.3
  
  # 图表库
  fl_chart: ^0.68.0
  
  # 可选：AI功能
  # google_ml_kit: ^0.18.0
```

---

## 🎯 成功指标

### 用户满意度
- 应用商店评分提升至 4.8+
- 用户留存率提升 20%
- 日活用户增长 30%

### 功能覆盖率
- 核心功能完整度 > 90%
- 与竞争对手功能对齐度 > 85%
- 用户请求功能实现率 > 70%

### 技术指标
- 应用启动时间 < 2秒
- 内存占用 < 100MB
- 崩溃率 < 0.1%

---

## 📝 备注

1. **优先级调整**: 根据用户反馈和开发进度，优先级可能调整
2. **技术债务**: 在实现新功能时，同步优化现有代码
3. **测试覆盖**: 每个新功能需编写单元测试和集成测试
4. **文档更新**: 每个功能完成后更新用户文档和开发文档
5. **性能监控**: 持续监控应用性能，确保新功能不影响整体体验

---

**创建日期**: 2026-04-30  
**最后更新**: 2026-04-30  
**维护者**: Sisyphus AI Agent
