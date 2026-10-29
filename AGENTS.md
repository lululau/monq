# AGENTS.md

monq 是发布到 RubyGems（<https://rubygems.org>）的 Ruby gem，用 Bundler 管理。

## 版本号

唯一来源是 `lib/monq/version.rb` 中的 `Monq::VERSION`，`monq.gemspec` 从这里读取。
不要在 gemspec 里写死版本号。

## 升级版本号：`gem bump`

`gem bump` 由 [gem-release](https://github.com/svenfuchs/gem-release) 提供：

```bash
gem bump                  # 默认升 patch：0.1.0 -> 0.1.1
gem bump --version minor  # 升 minor：0.1.0 -> 0.2.0
gem bump --version major  # 升 major：0.1.0 -> 1.0.0
```

注意：

- 本机的 gem-release（2.2.x）中，`gem bump` **默认会自动创建 commit**
  （提交消息为 `Bump monq to x.y.z`，仅含 `version.rb`），可用 `--no-commit` 关闭。
- `Gemfile.lock` 里固定了 monq 自身版本，bump 后会过期。
  运行一次 `bundle install`（或任意 `bundle exec` 命令）即可自动刷新，
  之后把 `Gemfile.lock` 单独提交。

## 发布到 RubyGems：`rake release`

```bash
rake release
```

`rake release` 由 Rakefile 中的 `bundler/gem_tasks` 提供，它会依次：

1. 构建 gem 到 `pkg/monq-<version>.gem`；
2. 创建 `v<version>` 标签（如 `v0.1.1`）并 push 到 git origin；
3. 执行 `gem push` 把 `.gem` 推送到 <https://rubygems.org>。

前置条件：

- 工作区必须干净——包括 `gem bump` 的改动在内的所有变更都要先 commit，
  否则 release 会中止；
- 本机已配置 rubygems.org 的 `gem push` 凭据；
- RubyGems 不允许重复推送同一版本号，重发前必须先 bump。

## 完整流程示例

```bash
bundle exec rspec        # 发布前先跑测试
gem bump                 # 升 patch 版本并自动提交 version.rb
bundle install           # 刷新 Gemfile.lock 中 monq 自身版本
git add Gemfile.lock && git commit -m "chore: update Gemfile.lock"
rake release             # 构建、打 tag、推送到 RubyGems
```
