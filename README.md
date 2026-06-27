# Jimmy Blog

Jimmy 的个人技术博客，主要记录 AI 编程、开发工具与实际应用。

- 网站：<https://blog.jebhenry.dpdns.org/>
- GitHub：<https://github.com/jimmy6270>

## 本地运行

需要 Ruby、Bundler 和 Node.js。

```sh
bundle install
bundle exec jekyll serve
```

默认访问地址为 <http://localhost:4000>。

## 发布

推送到 `master` 后，GitHub Actions 会构建并部署 GitHub Pages。自定义域名记录在根目录 `CNAME`。

## 主题与许可

本站主题基于 [Hux Blog](https://github.com/Huxpro/huxpro.github.io)，并派生自 Clean Blog Jekyll Theme。

主题代码继续遵循仓库内 [Apache License 2.0](LICENSE) 及相关第三方许可。
