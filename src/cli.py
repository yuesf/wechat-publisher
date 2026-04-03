"""
CLI 入口
"""

import asyncio
import re
from pathlib import Path
from typing import Optional

import httpx
from PIL import Image, ImageDraw
from rich.console import Console
from rich.table import Table
import typer

from .config import settings
from .platforms import WeChatPlatform, PublishRequest

app = typer.Typer(
    name="wechat-publisher",
    help="微信公众号文章发布工具",
)
console = Console()


def create_wechat_platform() -> WeChatPlatform:
    """创建微信平台实例"""
    settings.load()
    if not settings.is_wechat_configured():
        raise RuntimeError("微信公众号未配置，请先运行 config 命令设置 app_id 和 app_secret")
    return WeChatPlatform(
        app_id=settings.wechat.app_id,
        app_secret=settings.wechat.app_secret,
    )


# 配置命令组
config_app = typer.Typer(help="配置管理")
app.add_typer(config_app, name="config")


@config_app.command("init")
def config_init() -> None:
    """初始化配置文件"""
    settings.save()
    console.print(f"[green]配置文件已创建: {settings.get_config_file()}[/green]")


@config_app.command("show")
def config_show() -> None:
    """显示当前配置"""
    settings.load()

    table = Table(title="配置信息")
    table.add_column("配置项", style="cyan")
    table.add_column("值", style="green")

    table.add_row("配置文件", str(settings.get_config_file()))
    table.add_row("微信 AppID", settings.wechat.app_id or "[red]未配置[/red]")
    table.add_row("微信 Secret", "***" if settings.wechat.app_secret else "[red]未配置[/red]")

    console.print(table)


@config_app.command("set")
def config_set(
    key: str = typer.Argument(..., help="配置键，格式: section.key"),
    value: str = typer.Argument(..., help="配置值"),
) -> None:
    """设置配置项

    示例:
        wechat-publisher config set wechat.app_id your_app_id
        wechat-publisher config set wechat.app_secret your_secret
    """
    settings.load()

    parts = key.split(".")
    if len(parts) != 2:
        console.print("[red]错误: 配置键格式应为 section.key[/red]")
        raise typer.Exit(1)

    section, subkey = parts

    if section == "wechat":
        if subkey == "app_id":
            settings.wechat.app_id = value
        elif subkey == "app_secret":
            settings.wechat.app_secret = value
        else:
            console.print(f"[red]未知配置项: {key}[/red]")
            raise typer.Exit(1)
    else:
        console.print(f"[red]未知配置节: {section}[/red]")
        raise typer.Exit(1)

    settings.save()
    console.print(f"[green]已设置 {key}[/green]")


# 发布命令
@app.command()
def publish(
    file: Path = typer.Argument(..., help="HTML 文件路径", exists=True),
    title: Optional[str] = typer.Option(None, "--title", "-t", help="文章标题（默认从文件名提取）"),
    cover: Optional[str] = typer.Option(None, "--cover", "-c", help="封面图片路径"),
    author: Optional[str] = typer.Option(None, "--author", "-a", help="作者"),
) -> None:
    """发布 HTML 文件到微信公众号草稿箱

    直接发布 HTML 文件，不进行任何转换。适用于已准备好的 HTML 内容。
    """
    if not file.exists():
        console.print(f"[red]文件不存在: {file}[/red]")
        raise typer.Exit(1)

    # 读取 HTML 内容
    html_content = file.read_text(encoding="utf-8")

    # 确定标题
    article_title = title or file.stem
    if not title:
        # 尝试从 HTML 中提取标题
        title_match = re.search(r"<h1[^>]*>([^<]+)</h1>", html_content)
        if title_match:
            article_title = title_match.group(1)
        else:
            title_match = re.search(r"<title>([^<]+)</title>", html_content)
            if title_match:
                article_title = title_match.group(1)

    console.print(f"[cyan]发布 HTML 文件: {file}[/cyan]")
    console.print(f"[cyan]标题: {article_title}[/cyan]")

    # 发布到平台
    try:
        wechat = create_wechat_platform()
    except RuntimeError as e:
        console.print(f"[red]{e}[/red]")
        raise typer.Exit(1)

    request = PublishRequest(
        title=article_title,
        content=html_content,
        cover=cover,
        author=author,
    )

    result = asyncio.run(wechat.publish(request))

    if result.success:
        console.print(f"[green]发布到 {wechat.display_name} 成功！[/green]")
        if result.media_id:
            console.print(f"  Media ID: {result.media_id}")
        if result.article_url:
            console.print(f"  URL: {result.article_url}")
    else:
        console.print(f"[red]发布到 {wechat.display_name} 失败: {result.message}[/red]")
        raise typer.Exit(1)


# 测试命令
@app.command()
def test() -> None:
    """测试微信公众号连接"""
    try:
        wechat = create_wechat_platform()
    except RuntimeError as e:
        console.print(f"[red]{e}[/red]")
        raise typer.Exit(1)

    console.print(f"[cyan]测试 {wechat.display_name} 连接...[/cyan]")

    result = asyncio.run(wechat.validate_credentials())

    if result:
        console.print(f"[green]{wechat.display_name} 连接成功！[/green]")
    else:
        console.print(f"[red]{wechat.display_name} 连接失败[/red]")
        raise typer.Exit(1)


# 上传图片命令
@app.command()
def upload_image(
    file: Path = typer.Argument(..., help="图片文件路径", exists=True),
) -> None:
    """上传图片到微信素材库"""
    try:
        wechat = create_wechat_platform()
    except RuntimeError as e:
        console.print(f"[red]{e}[/red]")
        raise typer.Exit(1)

    console.print(f"[cyan]上传图片: {file}[/cyan]")

    result = asyncio.run(wechat.upload_image(str(file)))

    if result.success:
        console.print(f"[green]图片上传成功！[/green]")
        if result.media_id:
            console.print(f"  Media ID: {result.media_id}")
        if result.url:
            console.print(f"  URL: {result.url}")
    else:
        console.print(f"[red]图片上传失败: {result.message}[/red]")
        raise typer.Exit(1)


if __name__ == "__main__":
    app()
