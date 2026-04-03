# WeChat Publisher

微信公众号文章发布工具

## 安装

```bash
pip install -e .
```

## 配置

```bash
# 初始化配置
wechat-publisher config init

# 设置 AppID 和 AppSecret
wechat-publisher config set wechat.app_id your_app_id
wechat-publisher config set wechat.app_secret your_app_secret

# 查看当前配置
wechat-publisher config show
```

## 使用

```bash
# 发布 HTML 文件到微信公众号草稿箱
wechat-publisher publish article.html

# 指定标题
wechat-publisher publish article.html --title "文章标题"

# 指定封面图片
wechat-publisher publish article.html --cover cover.jpg

# 测试连接
wechat-publisher test

# 上传图片
wechat-publisher upload-image image.jpg
```

## 环境变量

也可以通过环境变量配置：

- `WECHAT_PUBLISHER_WECHAT_APP_ID`
- `WECHAT_PUBLISHER_WECHAT_APP_SECRET`

## 从 article-publisher 剥离

本项目从 multi-writing-skills 项目中剥离，专门用于微信公众号发布功能。
