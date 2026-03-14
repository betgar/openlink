# 脚本工具目录

此目录包含 OpenLink 项目的各种辅助脚本。

## 目录结构

```
scripts/
├── deploy-extension.sh     # 扩展部署准备脚本
├── test-platform.sh        # 平台功能测试脚本
└── README.md             # 说明文档
```

## 脚本说明

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
