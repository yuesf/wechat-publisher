# wechat-publisher Skill

微信公众号文章发布工具，完全独立实现，不依赖任何外部 CLI 工具。

## 功能特性

- **纯 Python 实现**: 不依赖 wenyan-cli 或其他外部工具
- **Markdown 转换**: 内置 Markdown → HTML 转换（参考 wenyan 风格）
- **多主题支持**: 多种精美主题（lapis、phycat、default 等）
- **代码高亮**: 9 种代码高亮主题
- **图片自动处理**: 本地/网络图片自动上传到微信图床
- **AI 去痕**: 发布前自动 AI 去痕处理，让内容读起来更像真人写的
- **封面生成**: 自动处理封面图，支持本地/网络图片

## 触发条件

当用户需要以下操作时自动触发：
- 将 Markdown 或 HTML 文章发布到微信公众号草稿箱
- 转换 Markdown 为公众号格式 HTML
- 使用特定主题发布公众号文章
- 测试微信连接

## 安装

```bash
# 安装依赖
pip install wechat-publisher

# 或者开发模式
git clone https://github.com/yuesf/wechat-publisher.git
cd wechat-publisher
pip install -e .
```

## 配置

### 方式 1: 环境变量

```bash
export WECHAT_APP_ID=your_wechat_app_id
export WECHAT_APP_SECRET=your_wechat_app_secret

# AI 去痕（可选）
export AI_API_KEY=your_api_key
export AI_PROVIDER=qwen  # openai, qwen, zhipu, doubao, minimax, moonshot, hunyuan, yi
```

### 方式 2: 配置文件

```bash
# 初始化配置
wechat-publisher config init

# 设置配置
wechat-publisher config set wechat.app_id <AppID>
wechat-publisher config set wechat.app_secret <AppSecret>
wechat-publisher config set ai.api_key <API Key>
wechat-publisher config set ai.provider qwen
```

### 3. IP 白名单

确保运行机器的 IP 已添加到微信公众号后台白名单：
- 登录 https://mp.weixin.qq.com/
- 设置与开发 → 基本配置 → IP白名单

## 使用方式

### 基本发布

```bash
# 发布 HTML 文件到草稿箱
wechat-publisher publish article.html

# 指定标题和封面
wechat-publisher publish article.html --title "文章标题" --cover cover.jpg

# 不使用 AI 去痕
wechat-publisher publish article.html --no-humanize

# 调整 AI 去痕强度
wechat-publisher publish article.html --intensity heavy
```

### 测试连接

```bash
wechat-publisher test
```

### 上传图片

```bash
wechat-publisher upload-image image.jpg
```

## AI 去痕

AI 去痕是可选功能，让文章读起来更自然。支持的 Provider：

| Provider | 说明 |
|----------|------|
| openai | OpenAI GPT 系列 |
| qwen | 通义千问（默认） |
| zhipu | 智谱 GLM |
| doubao | 豆包 |
| minimax | MiniMax |
| moonshot | Moonshot |
| hunyuan | 腾讯混元 |
| yi | 零一万物 |

去痕强度：
- `light` - 轻度：保持原文大部分内容，只做轻微调整
- `medium` - 中度：适度调整，保留核心内容
- `heavy` - 重度：大幅调整，使文章焕然一新

## 故障排查

### 错误：未能找到文章封面
- 原因：未提供封面图片
- 解决：使用 `--cover` 参数指定封面

### 错误：45166 (IP地址不在白名单中)
- 原因：运行机器的 IP 未添加到微信白名单
- 解决：登录公众号后台添加 IP 到白名单

### 发布成功但看不到文章？
- 原因：文章在草稿箱，需要审核发布
- 解决：草稿箱 → 选中文章 → 发布

## 架构说明

```
wechat-publisher/
├── src/wechat_publisher/
│   ├── cli.py         # CLI 入口
│   ├── config.py      # 配置管理
│   ├── humanizer/     # AI 去痕模块
│   └── platforms/     # 平台适配器
│       └── wechat.py  # 微信公众号 API
└── pyproject.toml
```

## 设计参考

本项目参考了以下优秀项目的设计思路：
- **wenyan-cli**: Markdown 转微信 HTML 的排版思路
- **wechat-publisher**: 微信公众号 API 调用的封装方式

但本项目是完全独立实现的，不依赖任何外部工具。

## 作者

yuesf

## 许可证

MIT
