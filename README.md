# wechat-publisher

把文章发到微信公众号草稿箱，发布前自动 AI 去痕，让内容读起来更像真人写的。

## 装上

```bash
pip install wechat-publisher
```

## 配一下

```bash
# 初始化
openclaw config init

# 微信公众号的凭证
openclaw config set wechat.app_id <你的AppID>
openclaw config set wechat.app_secret <你的AppSecret>

# AI 去痕用的 API（可选，但建议配）
openclaw config set ai.api_key <你的API Key>
openclaw config set ai.provider qwen  # 或者 openai、zhipu 等
```

## 用一下

```bash
# 把 HTML 文章发到公众号草稿箱，自动 AI 去痕
wechat-publisher publish article.html

# 不用 AI 去痕
wechat-publisher publish article.html --no-humanize

# 指定标题和封面
wechat-publisher publish article.html --title "文章标题" --cover cover.jpg

# 调过去痕强度
wechat-publisher publish article.html --intensity light   # 轻度
wechat-publisher publish article.html --intensity heavy  # 重度

# 看看配置对不对
wechat-publisher config show

# 测试微信连接
wechat-publisher test
```

## 环境变量

不想用 config 命令？直接环境变量：

```bash
export WECHAT_PUBLISHER_WECHAT_APP_ID=xxx
export WECHAT_PUBLISHER_WECHAT_APP_SECRET=xxx
export WECHAT_PUBLISHER_AI_API_KEY=xxx
export WECHAT_PUBLISHER_AI_PROVIDER=qwen
```

## Claude Code 里用

在 Claude Code 里直接说人话：

- "把这篇 article.html 发到公众号"
- "帮我发布到微信，用重度去痕"
- "测试一下微信连接"

## 支持的 AI Provider

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

## 开发

```bash
git clone https://github.com/yuesf/wechat-publisher.git
cd wechat-publisher
pip install -e .
wechat-publisher --help
```

## 从 article-publisher 剥离

这个项目从 [article-publisher](https://github.com/yuesf/article-publisher) 里剥离出来的，专门用来发公众号。

## License

MIT
