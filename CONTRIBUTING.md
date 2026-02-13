# 贡献指南

感谢你对「萤」项目的关注！本文档将帮助你了解如何为项目做出贡献。

## 目录

- [开发环境设置](#开发环境设置)
- [代码规范](#代码规范)
- [提交规范](#提交规范)
- [测试要求](#测试要求)
- [Pull Request 流程](#pull-request-流程)

## 开发环境设置

### 前置要求

- **Flutter SDK**: >= 3.9.2
- **Dart SDK**: >= 3.9.2
- **Android Studio** 或 **VS Code**（推荐安装 Flutter 插件）
- **Git**: 版本控制

### 初始化项目

```bash
# 1. Fork 并克隆仓库
git clone https://github.com/YOUR_USERNAME/ying.git
cd ying

# 2. 添加上游仓库
git remote add upstream https://github.com/jiuxina/ying.git

# 3. 安装依赖
flutter pub get

# 4. 运行代码检查
flutter analyze

# 5. 运行测试
flutter test

# 6. 运行应用
flutter run
```

## 代码规范

### 架构原则

本项目采用 **MVVM（Model-View-ViewModel）** 架构：

- **Models** (`lib/models/`): 数据模型，纯 Dart 类
- **Providers** (`lib/providers/`): 状态管理，使用 Provider 模式
- **Services** (`lib/services/`): 业务逻辑，如数据库、网络请求
- **Screens** (`lib/screens/`): 页面视图
- **Widgets** (`lib/widgets/`): 可复用组件

### 编码规范

#### 1. Lint 规则

项目已配置严格的 lint 规则（`analysis_options.yaml`），请确保代码通过所有检查：

```bash
flutter analyze
```

#### 2. 异常处理

使用类型化异常而非通用的 `catch (e)`：

```dart
// ✅ 推荐
try {
  await service.fetchData();
} on NetworkException catch (e) {
  debugPrint('网络错误: $e');
  // 处理网络错误
} on ValidationException catch (e) {
  debugPrint('验证错误: $e');
  // 处理验证错误
} catch (e) {
  debugPrint('未知错误: $e');
  // 处理其他错误
}

// ❌ 不推荐
try {
  await service.fetchData();
} catch (e) {
  // 太宽泛，难以调试
}
```

**可用的异常类型**：
- `DatabaseException` - 数据库操作错误
- `NetworkException` - 网络请求错误
- `ValidationException` - 输入验证错误
- `FileSystemException` - 文件系统错误
- `CloudSyncException` - 云同步错误
- `PermissionException` - 权限错误

#### 3. 输入验证

始终验证和清理用户输入：

```dart
// ✅ 验证 URL
if (!uri.scheme.startsWith('http')) {
  throw ValidationException('URL 必须以 http 或 https 开头');
}

// ✅ 清理文件路径
String sanitizePath(String path) {
  return path.trim()
    .replaceAll('..', '')  // 防止路径遍历
    .replaceAll(RegExp(r'/+'), '/');  // 清理多余斜杠
}
```

#### 4. 常量使用

将所有硬编码值提取到 `lib/utils/constants.dart`：

```dart
// ✅ 使用常量
await HomeWidget.setAppGroupId(AppConstants.appGroupId);

// ❌ 硬编码
await HomeWidget.setAppGroupId('com.jiuxina.ying');
```

#### 5. 文档注释

为所有公共 API 添加 dartdoc 注释：

```dart
/// 备份服务
///
/// 提供数据备份和恢复功能，支持导出为 JSON 文件和从 JSON 文件恢复数据。
class BackupService {
  /// 创建备份文件并分享
  ///
  /// 导出所有数据为 JSON 格式，生成带时间戳的备份文件。
  ///
  /// 抛出：
  /// - [FileSystemException] 如果文件创建失败
  /// - [AppException] 如果备份过程中发生其他错误
  Future<void> createBackup() async {
    // ...
  }
}
```

#### 6. 性能优化

- 使用 `const` 构造函数（lint 会提示）
- 避免不必要的 `setState()` 调用
- 使用 `context.select()` 而非 `context.watch()` 精确监听状态
- 单次遍历而非多次 `where().toList()`

```dart
// ✅ 单次过滤
final events = provider.events.where((e) {
  if (e.isArchived) return false;
  if (categoryId != null && e.categoryId != categoryId) return false;
  return true;
}).toList();

// ❌ 多次过滤（性能差）
var events = provider.events.where((e) => !e.isArchived).toList();
events = events.where((e) => e.categoryId == categoryId).toList();
```

### 数据库规范

#### 表名使用常量

```dart
// 使用 AppConstants 中的表名常量
const String table = AppConstants.eventsTable;
```

#### 索引优化

频繁查询的字段应添加索引：

```sql
CREATE INDEX idx_events_category ON events(category);
CREATE INDEX idx_events_archived ON events(isArchived);
```

当前已有索引：
- `idx_events_category` - 分类过滤
- `idx_events_archived` - 归档状态
- `idx_events_pinned` - 置顶状态
- `idx_events_target_date` - 日期排序
- `idx_events_group_id` - 分组查询
- `idx_reminders_event_id` - 提醒查询

## 测试要求

### 单元测试

为所有业务逻辑编写单元测试：

```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/providers/events_provider_test.dart

# 查看覆盖率
flutter test --coverage
```

### 测试覆盖要求

- **核心服务**: > 80% 覆盖率（DatabaseService, CloudSyncService）
- **Provider**: > 70% 覆盖率
- **Widgets**: 关键交互需有测试

### 测试示例

```dart
test('应该正确过滤已归档的事件', () {
  final provider = EventsProvider();
  // ... 添加测试事件

  final activeEvents = provider.events.where((e) => !e.isArchived).toList();
  expect(activeEvents.length, 2);
});
```

## 提交规范

### Commit Message 格式

采用约定式提交（Conventional Commits）：

```
<type>(<scope>): <subject>

<body>

<footer>
```

**类型（type）**：
- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 重构（不是新功能也不是修复）
- `perf`: 性能优化
- `test`: 添加或修改测试
- `chore`: 构建过程或辅助工具的变动

**示例**：

```bash
feat(backup): 添加自动备份功能

实现了每日自动备份到云端的功能，用户可在设置中配置。

Closes #123
```

## Pull Request 流程

### 1. 创建功能分支

```bash
git checkout -b feat/your-feature-name
```

### 2. 开发并提交

```bash
git add .
git commit -m "feat(scope): 描述你的更改"
```

### 3. 保持分支更新

```bash
git fetch upstream
git rebase upstream/main
```

### 4. 推送并创建 PR

```bash
git push origin feat/your-feature-name
```

然后在 GitHub 上创建 Pull Request。

### 5. PR 检查清单

提交 PR 前请确保：

- [ ] 代码通过 `flutter analyze` 检查
- [ ] 所有测试通过 `flutter test`
- [ ] 添加了必要的测试
- [ ] 更新了相关文档
- [ ] Commit message 符合规范
- [ ] PR 描述清晰，说明了改动的原因和影响

### 6. Code Review

- 维护者会审查你的代码
- 根据反馈进行必要的修改
- 所有讨论解决后，PR 将被合并

## 问题反馈

发现 bug 或有功能建议？请：

1. 检查是否已有相关 Issue
2. 如果没有，[创建新 Issue](https://github.com/jiuxina/ying/issues/new)
3. 清晰描述问题或建议
4. 如果是 bug，提供复现步骤和环境信息

## 联系方式

- **Email**: jiuxina@outlook.com
- **GitHub Issues**: https://github.com/jiuxina/ying/issues

---

再次感谢你的贡献！🎉
