# Monq: MongoDB + Pry 查询工作台

**Date:** 2026-10-24  
**Status:** Draft for implementation  
**Repo:** `monq`（`bundle gem monq` 脚手架，独立于 `arql`）

## 1. 问题与目标

Arql 把 ActiveRecord + Pry 做成 SQL 工作台：YAML 多环境、SSH 隧道、动态模型、Pry 命令、表格/导出。MongoDB 没有表 schema，不能作为 Arql 的 adapter 塞进去。

Monq 是平行产品：**Mongoid + Pry 的 Mongo 工作台**。同一套 REPL 肌肉记忆，数据层换成 Mongoid。用户在 `~/.monq.d/init.yml` 里写连接，在 `~/.monq.d/*.rb` 里写 `Mongoid::Document` 模型。不扫集合自动造类。

第一版要对齐 Arql 的 REPL 体验（`info` / `m` / `sandbox` / `show-sql` / `reconnect` / `t`/`v`/`vd` / CSV·Excel），而不是只做一个能 `load` 模型的 console。

成功标准：

- `monq -e fof.dev` 连上 `fof_dev`，load `~/.monq.d/fof.rb`，进入 Pry。
- `Fund.where(fund_name: 'MW Alpha Plus Fund').t` 打出表格。
- 多环境 `monq -e a,b` 各有 namespace 和 Mongoid client。
- 未建模集合可通过 `Fof.client[:jobs].find(...).to_a.t` 查询。

## 2. 已拍板的约束

| 决策 | 选择 |
|------|------|
| 模型来源 | 只加载用户写的模型，不 `list_collections` 造类 |
| 模型 API | `Mongoid::Document` |
| 第一版范围 | 尽量对齐 Arql REPL |
| 模型文件 | 文件名 = 环境名前缀（`fof.dev` → `fof.rb`） |
| 连接配置 | URI 优先，否则拆字段拼 client |
| 多环境 | 与 Arql 相同，顶层 `const_missing` 按 `-e` 顺序别名 |
| SSH | 第一版内置，结构对齐 Arql |
| 实现策略 | 平行复制 Arql 的壳，不抽 `arql-shell`，不依赖 `arql` gem |
| 测试库 | `fof_dev` @ `10.0.0.12`（凭证只放本机 YAML / 环境变量，不进 git） |

## 3. 架构与启动流程

```
exe/monq
  └─ Monq::Cli.start
       ├─ 读配置（默认 ~/.monq.d/init.yml）
       ├─ 解析 -e env1,env2（分隔符：`,` `+` `:`）
       └─ App.new(options).run!
            ├─ 每个环境 new Environment
            │     ├─ SSH 隧道（可选）
            │     ├─ 创建 namespace 模块
            │     ├─ 注册命名 Mongoid client
            │     └─ load 模型文件
            │           ~/.monq.d/init.rb     # 全局，整个进程 load 一次
            │           ~/.monq.d/<prefix>.rb # load 进该环境的 namespace 模块
            ├─ 扫描 namespace 内的 Mongoid::Document
            │     顶层文档类补 store_in client: <client_name>
            │     嵌入文档（embedded）不补
            └─ 执行
                  ├─ TTY 且无 -E / 文件 → Pry
                  ├─ -E CODE → eval
                  ├─ 文件参数 → load
                  └─ STDIN 非 tty → eval stdin
```

配置路径（先命中的文件生效）：

| 用途 | 候选路径 |
|------|----------|
| 连接 YAML | `-c` > `~/.monq.d/init.yml` > `~/.monq.d/init.yaml` > `~/.monq.yml` > `~/.monq.yaml` |
| 全局 initializer | `-i` > `~/.monq.d/init.rb` > `~/.monq.rb` |
| 环境模型 | 始终从 initializer 所在目录的兄弟文件加载：默认 `~/.monq.d/<prefix>.rb`。若 `-i` 指向别的文件，前缀模型仍从 `~/.monq.d/` 加载（不随 `-i` 搬家，避免意外） |

`App` 是单例。Pry 命令、`Kernel` 扩展只通过 `App.instance` 拿环境列表。

多环境时禁止 CLI 覆盖单连接字段（`--uri` / `--host` / `--ssh-*` 等），与 Arql 相同，避免歧义。

## 4. 单元与接口

每个单元只做一件事，命令层不直接碰 Mongoid 配置哈希。

### 4.1 `Monq::Cli`

- 解析 ARGV 到 `OpenStruct`。
- 选项：`-c` `-i` `-e` `-E` `-b`（babel）`-S` `-w` `-A` `--version` `--help`。
- 连接覆盖：`--uri` `--db-host` `--db-port` `--db-name` `--db-user` `--db-password` `--auth-source`。
- SSH：`--ssh-host` `--ssh-port` `--ssh-user` `--ssh-password` `--ssh-local-port`。
- 不连接数据库。把 options 交给 `App`。

### 4.2 `Monq::App`

- 读 YAML（`YAML.safe_load(..., aliases: true)`，兼容无 aliases 的旧 Psych）。
- 按 `-e` 切片环境；无 `-e` 时若 CLI 给了足够连接信息，合成名为 `default` 的临时环境。
- 为每个环境实例化 `Environment` 并 `connect!` + `load_models!`。
- `run!` 选择 REPL / eval / load。
- 持有 `log_io`（`MultiIO`），供 `show-sql` 与 `-S`/`-w`/`-A` 使用。

### 4.3 `Monq::Environment`

一个 `-e` 段的全部运行时状态。

| 方法 | 职责 |
|------|------|
| `name` | YAML 键，如 `fof.dev` |
| `namespace` | 模块名字符串 |
| `namespace_module` | 该模块 |
| `client_name` | Mongoid client 符号。`fof.dev` → `:fof_dev`（非 `[A-Za-z0-9]` 换成 `_`） |
| `config` | 该环境合并后的配置 Hash（含自定义键） |
| `connect!` | SSH（若有）→ 注册 client → ping |
| `reconnect!` / `ping?` | 重建 client / `hello` 或 `ping` |
| `load_models!` | load 前缀文件到 namespace，绑定 `store_in client:`，生成缩写常量 |
| `redefine!` | 移除本 namespace 下由 Monq 挂上的模型/缩写常量，再 `load_models!`。不重新 load 全局 `init.rb` |
| `models` | 顶层 Document 类数组（排除 embedded） |
| `client` | `Mongo::Client` |
| `sandbox_enter` / `sandbox_quit` | 见第 7 节 |
| `command(doc)` | `client.database.command(doc)`。namespace 模块上的 `q` 转发到这里 |

`Environment` 不负责打表、不注册 Pry 命令。

### 4.4 `Monq::SSHProxy`

- 输入：`host` `user` `port` `password` + 要转发的 Mongo `forward_host`/`forward_port` + 可选 `local_port`。
- 用 `Net::SSH::Gateway` 打开本地端口。
- `database_host_port` → `{ host: '127.0.0.1', port: local_port }`，供拼 client 时替换。
- `active?` / `reconnect` / `reconnect!` 与 Arql 同语义。

有 `uri` 又有 `ssh` 时：先按 URI 解析 hosts，再把 hosts 改成 `127.0.0.1:local_port`（副本集多 host 时，第一版只转发 URI 里的第一个 host；文档中写明限制）。

### 4.5 `Monq::Repl`

- 自定义 Pry prompt：`MONQ@<env[+env]> [sandbox] [n] ❯`。
- `-b` 时不改 prompt。
- `Pry.start` 前 `require 'monq/commands'`。

### 4.6 `Monq::Commands::*`

每个文件注册 Pry 命令，读 `App.instance.environments`。命令逻辑放在模块单例方法上，便于单测字符串输出。

### 4.7 展示

- `Monq::Table`：terminal / md / org / HTML（IRuby 若存在）。
- `Monq::VD`：把行写成 CSV 交给 `vd`。
- `Monq::Presenter`：BSON → 可打印（见 6.2）。
- `Monq::MultiIO`：日志扇出；非 tty 剥 ANSI。

### 4.8 扩展

| 文件 | 给谁 |
|------|------|
| `ext/object.rb` | `const_missing` 顶层别名；`j`/`jj` 可选，非必须 |
| `ext/kernel.rb` | `models` `model_names` `within_namespace` `within_env` `env_config` `generate_csv` `parse_excel` 等；全局 `q` 仅单环境 |
| `ext/document.rb` | Mongoid 文档实例 `t` `v` `vd` `write_csv` `write_excel` |
| `ext/criteria.rb` | `Mongoid::Criteria` 同上，先物化 |
| `ext/array.rb` `ext/hash.rb` | 与 Arql 同：数组/Hash 打表与导出。Hash 的 `write_excel` 多 sheet |
| `ext/view.rb` | `Mongo::Collection::View#t` 等：`to_a` 后走 Array |

嵌入文档实例也走 Document 扩展（当一行的嵌套对象打印）。

## 5. 配置与模型加载

### 5.1 YAML

```yaml
default: &default
  auth_source: admin

fof.dev:
  <<: *default
  uri: mongodb://USER:PASS@10.0.0.12:27017/?authSource=admin
  database: fof_dev
  namespace: Fof
  ssh:
    host: jump.example.com
    user: deploy
    port: 22
    local_port: 27018
```

| 键 | 规则 |
|----|------|
| `uri` | 有则作为 client 地址来源。密码可含需 URL 编码的字符 |
| `database` | 逻辑库名。URI 路径无库名时**必填**。测试库为 `fof_dev` |
| `host` `port` `username` `password` `auth_source` `replica_set` `ssl` | 无 `uri` 时拼 hosts/options |
| `namespace` | 缺省：环境名里非字母数字当分隔，CamelCase。`fof.dev` → `FofDev` |
| `ssh` | 同 Arql：`host` `port` `user` `password` `local_port` |
| 其它键 | 原样保留，`env_config(/fof/)` 可读 |

URI 与 `database` 同时存在：client 连 URI，`use`/`database` 以 `database` 键为准（覆盖 URI path）。

### 5.2 前缀匹配

环境名按 `.` `_` `-` 切第一段为前缀。

- `fof.dev` → `fof.rb`
- `blog` → `blog.rb`

文件不存在：警告，不失败（允许只连库、用 `client[:coll]` 查）。`init.rb` 不存在：静默跳过。

`load` 前缀文件时用 `namespace_module.module_eval` 等价上下文（`Kernel.load(path, wrap)` 不能注入模块；实现用 `namespace_module.module_eval(File.read(path), path)`，这样文件里顶层 `class Fund` 成为 `Fof::Fund`）。

全局 `init.rb` 用普通 `load`，在 `Object` 上下文，供跨环境 helper。**每个进程只 load 一次**，在所有 `Environment#connect!` 之后、各环境 `load_models!` 之前。

### 5.3 绑定 client

`load_models!` 之后：

```
对 namespace_module 中 constants 递归（一层：该模块下的类，不含子模块深搜也可；第一版只扫 namespace 模块自身常量）
  若 klass < Mongoid::Document
    若 klass.embedded? → 跳过
    若 klass.storage_options[:client] 已由用户设置 → 不覆盖
    否则 klass.store_in client: client_name
```

用户可在模型里写 `store_in collection: 'Fund_approved'`；缺省 collection 仍是 Mongoid 对类名的 pluralize，所以 **fof 这种 PascalCase 集合名必须显式 `store_in collection:`**。README 示例写清楚。

### 5.4 缩写与顶层别名

- 缩写：类名中的大写字母（`MonthlyReturn` → `MR`）。冲突则 `MR2`、`MR3`… 挂在同一 namespace。
- `Object.const_missing`：按 `App` 里环境顺序，找第一个 `namespace_module.const_defined?(name)` 的常量。找不到则 `super`。
- 第一版不做 YAML `model_names` 覆盖。

### 5.5 Namespace 模块 API

在 `create_namespace_module` 时定义：

- `Fof.client` → `Mongo::Client`
- `Fof.models` → Document 类
- `Fof.collections` → `client.database.collection_names`（探索，不造类）
- `Fof.config` → 该环境 config
- `Fof.q(doc)` → `command(doc)`
- `Fof.dump`：第一版**不实现**（属于砍掉的 mongodump）

## 6. REPL 与展示

### 6.1 Pry 命令

| 命令 | 行为 |
|------|------|
| `info [regexp]` | 匹配环境的：name、database、client 名、ping、URI（user/password 打码）、SSH active/local_port |
| `m` / `l` | 已加载模型表：Table Name（collection）、Model Class、Abbr。`-e` 环境正则。第一版不做 `-c` 列扫描、不做 `-f sql`（无 CREATE TABLE）。`-f md\|org\|terminal` 要做 |
| `show-sql` / `hide-sql` | 开关 command 日志。实现：订阅 `Mongo::Monitoring::COMMAND` 或提高 `Mongo::Logger` 并把输出写入 `App.log_io`。filter/command 打成可读 JSON，避免 BSON 二进制 |
| `reconnect` | 每环境：SSH `reconnect`（若配置了）；`ping?` 为假才 `reconnect!` client |
| `reconnect!` | 强制重建 SSH（若有）与 client |
| `sandbox-enter` / `sandbox-quit` | 第 7 节 |
| `redefine` / `redef` | 每环境 `redefine!`（只重载前缀模型文件，不重载全局 init.rb） |

`-S` 启动即 `show-sql`；`-w`/`-A` 把同一 `log_io` 接到文件。

### 6.2 BSON 展示

`Presenter.scalar(value)`：

| 输入 | 输出 |
|------|------|
| `BSON::ObjectId` | 24 位 hex 字符串 |
| `Time` / `Date` | `YYYY-MM-DD HH:MM:SS`（本地） |
| `BSON::Binary` | `#<BSON::Binary type=.. size=n>` |
| `BSON::Decimal128` | `to_s` |
| `Hash` / `Array` | `as_json` 后的紧凑 JSON，超过 120 字符截断加 `…` |
| 其它 | `as_json` 或 `to_s` |

文档 `t`：表头为字段名（含 `_id`），值为 Presenter 后的标量。`_meta` 作为一列截断 JSON，不自动展开为多列。

Criteria / View：`limit` 未设时，打表前最多取 **500** 行，并在表下打印 `showing 500 of unknown` 或实际 `count`（若 count 便宜）。避免 `Fund.all.t` 拉爆内存。导出 `write_csv`/`write_excel` **不**套这 500 上限，但文档注明用户应自己 `limit`。

### 6.3 明确不做（第一版）

- 自动扫集合生成模型
- DDL（`create_table` / `add_column` 等）
- Ransack / `name_like`
- `mysqldump` / `to_insert_sql` / `mongoexport`
- YouPlot / Chartkick
- sandbox 提交（只有 rollback）
- YAML `model_names` / `rename_columns`

## 7. Sandbox、错误处理

### 7.1 Sandbox

`sandbox-enter` 对每个环境：

1. `hello = client.database.command(hello: 1).first`
2. 若无 `setName` 且 `msg != "isdbgrid"` → **失败**：打印「当前部署不支持事务（需要 replica set 或 mongos），未进入 sandbox」，该环境不标记 enabled。任一环境失败则整体不进入（全部回退），避免半开。
3. 否则 `session = client.start_session`；`session.start_transaction`；把 session 存到 `Environment`；将后续该 client 上的 Mongoid 持久化绑到此 session。

绑定方式（实现约束，不是用户 API）：REPL 不能包在 `with_session` 块里。使用 Mongoid 线程本地 session（`Mongoid::Threaded.set_session` 或等价公开/半公开 API）。若所用 Mongoid 版本没有稳定 setter，则在 `sandbox-enter` 时对 `Mongo::Client` 包装默认 session（仅该环境的 client）。规格要求：**该环境模型的 `save`/`update`/`delete`/`create` 走事务；`Fof.client[:x].insert_one` 第一版不保证进事务**，文档写明。

`sandbox-quit`：每个已开启的 session `abort_transaction` + `end_session`；清线程本地；prompt 去掉 sandbox。没有 commit 命令。

`sandbox-enter` 时已在 sandbox 中 → 提示已在，不嵌套。

### 7.2 错误

| 情况 | 行为 |
|------|------|
| `-e` 环境不在 YAML | 退出 1，列出已知键 |
| 无 `uri` 且无 `host`/`database` 足够信息 | 该环境失败，退出 1 |
| 有 `uri` 无 `database` 且 URI path 为空或 `/` | 退出 1，要求 `database:` |
| 模型文件语法/LoadError | 打印路径和异常，退出 1 |
| 连接/鉴权失败 | 打印打码 URI 与异常，退出 1 |
| 多环境调用全局 `q` | stderr 提示用 `Namespace.q`，返回 nil |
| `info` 密码 | 全部替换为 `*` |

日志与 `info` 不得出现明文密码。打码：URI 中 `://user:pass@` → `://user:***@`。

## 8. 针对 `fof_dev` 的模型约定（用户配置，不进 gem）

库里 64 个集合。第一版 gem **不** 携带这些模型。README 给最小示例，用户放 `~/.monq.d/fof.rb`：

- `_id` 均为 ObjectId，Mongoid 默认主键可用。
- 集合名是 `Fund_approved` 这种 PascalCase，必须 `store_in collection: 'Fund_approved'`。
- 关联是自然键 `fund_name` + `share_class_name`，不是 ObjectId `belongs_to`。示例用查询方法，不用默认 `has_many`。
- `month` / `inception_date` / `date` 是 **String**，`field type: String`，范围查询靠 `YYYY-MM` 字典序。
- `asset_classes` / `factors` / `sectors` / `indicators` 为动态键 Hash，`field type: Hash`。
- `_meta` 结构稳定，可用 `embeds_one` + `store_as: '_meta'`。嵌入类不要 `store_in client:`。

集成测试用 spec 内临时 Document 子类，不依赖用户的 `fof.rb`。

## 9. 依赖与仓库布局

**Runtime：** `mongoid` ~> 9.0（Ruby >= 3.2 的脚手架约束）、`pry`、`pry-byebug`、`net-ssh-gateway`、`terminal-table`、`rainbow`、`caxlsx`、`roo`。`mongo` 由 Mongoid 带入。

**Dev：** 已有 `rspec`、`rake`、`irb`。

**不引入：** ActiveRecord、Ransack、kaminari、youplot、chartkick、arql。

```
exe/monq
lib/monq.rb
lib/monq/cli.rb
lib/monq/app.rb
lib/monq/environment.rb
lib/monq/repl.rb
lib/monq/ssh_proxy.rb
lib/monq/table.rb
lib/monq/vd.rb
lib/monq/multi_io.rb
lib/monq/presenter.rb
lib/monq/commands/{info,models,reconnect,redefine,show_sql,sandbox}.rb
lib/monq/ext/{object,kernel,document,criteria,view,array,hash}.rb
spec/
docs/superpowers/specs/2026-10-24-monq-design.md
```

`exe/` 需加入 gemspec 的 `git ls-files` 可见文件；当前脚手架 **没有** `exe/`，实现时创建 `exe/monq`。

## 10. 测试

1. **单元（默认 rake spec）：** YAML 合并与 URI 优先；client 名与 namespace 默认；前缀 `fof.dev` → `fof.rb`；缩写冲突；Presenter；`const_missing` 顺序；命令模块在假 Environment 上的输出；URI 打码。不连网。
2. **集成（有 `MONQ_TEST_URI` 且 `MONQ_TEST_DB` 才跑，否则 skip）：** ping；`collection_names` 非空；临时 `store_in collection: 'Fund_approved'` 的模型 `count` >= 1；`where(fund_name: ...).limit(2).to_a` 能过 Presenter/`Table`。URI 只来自环境变量。
3. 不测 Pry TTY。不把 `10.0.0.12` 密码写进仓库或 CI 配置。

## 11. 实现顺序（给后续 plan 用，不是本 spec 的范围膨胀）

建议切片，便于单独 PR/提交：骨架 CLI+App+Environment 连接 → 模型 load 与 namespace → Repl 与展示 → Pry 命令 → SSH → sandbox → 导出/vd → 可选集成 spec。

本文件不规定每个函数的代码，只规定行为与边界。
