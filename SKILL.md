# wechat-publisher Skill

微信公众号文章发布 skill，基于 wenyan-cli + wechat-publisher。

## 功能特性

- **Markdown 转换**: 使用 wenyan-cli 将 Markdown 转换为精美的微信适配 HTML
- **多主题支持**: lapis、phycat、default、orange、purple 等精美主题
- **代码高亮**: 9 种代码高亮主题，Mac 风格代码块
- **图片自动处理**: 本地/网络图片自动上传到微信图床
- **AI 去痕**: 发布前自动 AI 去痕处理，让内容读起来更像真人写的
- **封面生成**: 自动处理封面图，支持本地/网络图片

## 触发条件

当用户需要以下操作时自动触发：
- 将 Markdown 文章发布到微信公众号草稿箱
- 转换 Markdown 为公众号格式 HTML
- 使用特定主题发布公众号文章
- 测试微信连接

## 工作流程

```
Markdown (含 frontmatter) → wenyan-cli 转换 → styled HTML → wechat-publisher 上传 → 草稿箱
```

## 前置要求

### 1. 安装依赖

```bash
# 安装 wenyan-cli (Node.js)
npm install -g @wenyan-md/cli

# 安装 wechat-publisher (Python)
pip install wechat-publisher
```

### 2. 配置微信公众号凭证

在 `~/.openclaw/.env` 中添加：

```bash
WECHAT_APP_ID=your_wechat_app_id
WECHAT_APP_SECRET=your_wechat_app_secret
```

或者通过命令行配置：

```bash
wechat-publisher config set wechat.app_id <AppID>
wechat-publisher config set wechat.app_secret <AppSecret>
```

### 3. IP 白名单

确保运行机器的 IP 已添加到微信公众号后台白名单：
- 登录 https://mp.weixin.qq.com/
- 设置与开发 → 基本配置 → IP白名单

## 使用方式

### 基本发布

```bash
# 使用默认主题发布
wechat-publisher publish-md article.md

# 指定主题
wechat-publisher publish-md article.md --theme lapis

# 指定代码高亮主题
wechat-publisher publish-md article.md --highlight monokai

# 不使用 AI 去痕
wechat-publisher publish-md article.md --no-humanize

# 调整 AI 去痕强度 (light/medium/heavy)
wechat-publisher publish-md article.md --intensity heavy
```

### 直接使用 wenyan-cli 转换

```bash
# 转换 Markdown 为 HTML（输出到 stdout）
wenyan render -f article.md

# 使用特定主题
wenyan render -f article.md -t lapis

# 指定代码高亮主题
wenyan render -f article.md -t lapis -h monokai

# 查看可用主题
wenyan theme list
```

### 测试连接

```bash
wechat-publisher test
```

## Markdown 格式要求

文件顶部必须包含 frontmatter：

```markdown
---
title: 文章标题（必填！）
cover: ./assets/cover.jpg # 封面图（必填！推荐 1080×864）
---

# 正文开始

你的内容...
```

### 封面图说明

- 相对路径（推荐）：`./assets/cover.jpg`
- 绝对路径：`/path/to/cover.jpg`
- 网络图片：`https://example.com/cover.jpg`
- 尺寸建议：1080×864（微信推荐比例）

### 可用主题

| 主题 | 风格 | 适合场景 |
|------|------|----------|
| lapis | 蓝色优雅 | 技术文章、教程 |
| phycat | 绿色清新 | 博客、随笔 |
| default | 经典简约 | 通用场景 |
| orange | 橙色活力 | 产品介绍 |
| purple | 紫色神秘 | 设计、创意 |

### 可用代码高亮

`solarized-light`, `monokai`, `github`, `atom-one-dark`, `dracula`, `nord`, `vs2015`, `highlightjs`, `prism`

## AI 去痕配置

AI 去痕是可选功能，需要配置 AI API：

```bash
# 配置 AI Provider
wechat-publisher config set ai.provider qwen  # 支持: openai, qwen, zhipu, doubao, minimax, moonshot, hunyuan, yi
wechat-publisher config set ai.api_key <your_api_key>
```

支持的 AI Provider：
- `openai` - OpenAI GPT 系列
- `qwen` - 通义千问（默认）
- `zhipu` - 智谱 GLM
- `doubao` - 豆包
- `minimax` - MiniMax
- `moonshot` - Moonshot
- `hunyuan` - 腾讯混元
- `yi` - 零一万物

## 故障排查

### 错误：未能找到文章封面
- 原因：frontmatter 缺少 cover 字段
- 解决：确保 frontmatter 包含 title 和 cover

### 错误：45166 (IP地址不在白名单中)
- 原因：运行机器的 IP 未添加到微信白名单
- 解决：登录公众号后台添加 IP 到白名单

### 发布成功但看不到文章？
- 原因：文章在草稿箱，需要审核发布
- 解决：草稿箱 → 选中文章 → 发布

### 图片上传失败？
- 原因：网络图片无法访问或格式不支持
- 解决：使用本地图片或检查网络连接

## 架构说明

```
wechat-publisher/
├── SKILL.md              # 本文档
├── publish.sh            # 发布脚本（自动加载凭证）
└── references/
    └── themes.md         # 主题列表
```

## 维护说明

- **wenyan-cli**: Node.js CLI 工具，负责 Markdown → HTML 转换和图片上传
- **wechat-publisher**: Python CLI 工具，负责 HTML → 微信草稿箱发布和 AI 去痕
- **配置文件**: `~/.wechat-publisher/config.yaml`
- **凭证读取**: 同时支持配置文件和环境变量（环境变量优先级更高）

## 作者

yuesf

## 许可证

MIT
