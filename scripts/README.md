# 脚本工具目录

此目录包含 OpenLink 项目的各种辅助脚本。

## 目录结构

```
scripts/
├── build.sh              # 本地构建脚本
├── deploy-extension.sh     # 扩展部署准备脚本
├── test-platform.sh        # 平台功能测试脚本
└── README.md             # 说明文档
```

## 脚本说明

### `build.sh`

**功能：** 本地构建 OpenLink 项目的各个组件

**使用方法：**
```bash
./scripts/build.sh [command]
```

**可用命令：**

- `server`: 构建服务端（当前平台） → 输出 `./openlink`
- `server-all`: 构建服务端（所有平台） → 输出到 `dist/`
- `extension`: 构建扩展并打包成 zip → 输出 `extension/dist/` 和 `openlink-extension-YYYYMMDD_HHMMSS.zip`
- `all`: 构建完整的项目（服务端 + 扩展）
- `clean`: 清理所有构建产物
- `help`: 显示帮助信息

**主要用途：**
- 本地开发时快速构建验证
- 不需要修改现有 GitHub release 流程
- 适用于本地调试和服务测试

### `deploy-extension.sh`

**功能：** 准备 Chrome 扩展的发布版本，包含构建验证、功能测试、打包等步骤

**使用方法：**
```bash
./scripts/deploy-extension.sh
```

**操作内容：**
- 构建最新扩展版本
- 验证构建产物完整性
- 检查平台配置
- 生成 ZIP 分发包
- 验证 Go 服务器编译

### `test-platform.sh`

**功能：** 测试各 AI 平台的配置是否正常恢复

**使用方法：**
```bash
./scripts/test-platform.sh
```

---

**注意：** 更高级别的脚本（如用户安装脚本）保留在项目根目录以便用户直接访问，例如 `install.sh`, `install.ps1` 等。

所有开发/维护脚本统一存放在此目录内，方便管理和维护。
