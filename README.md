# Monq: Mongoid + Pry MongoDB workbench

Load user-authored Mongoid models from `~/.monq.d` and query MongoDB from a Pry REPL.

## Install

```bash
gem install monq
```

From this repo:

```bash
bundle exec exe/monq
```

## Config

`~/.monq.d/init.yml`:

```yaml
blog.dev:
  uri: mongodb://USER:PASSWORD@db.example.com:27017/?authSource=admin
  database: blog_dev
  namespace: Blog
```

`USER` and `PASSWORD` are placeholders. Put real credentials only in your local YAML or in `MONQ_TEST_URI` / `MONQ_TEST_DB` for the optional integration spec. Do not commit them.

Start with `monq -e blog.dev`. The environment prefix (`blog`) loads `~/.monq.d/blog.rb` inside the `Blog` namespace.

## Models

`~/.monq.d/blog.rb`:

```ruby
class User
  include Mongoid::Document
  store_in collection: "users"
  field :name, type: String
  field :status, type: String
  embeds_one :meta, class_name: "UserMeta", store_as: "_meta"

  def posts
    Post.where(author_name: name)
  end
end

class UserMeta
  include Mongoid::Document
  embedded_in :user, class_name: "User"
  field :source, type: String
end

class Post
  include Mongoid::Document
  store_in collection: "posts"
  field :author_name, type: String
  field :title, type: String
  field :published_on, type: String
end
```

Write `class User`, not `class Blog::User`. The file is already evaluated inside the namespace, so the class becomes `Blog::User`.

String dates such as `published_on` (`YYYY-MM-DD`) sort lexicographically. Associations can be query methods on natural keys, not only ObjectId `belongs_to` / `has_many`. Non-pluralized collection names must be set with `store_in collection:`.

## Commands

| Command | What it does |
|---------|----------------|
| `info` | Matching environments: database, client, ping, masked URI, SSH |
| `m` / `l` | Loaded models: collection, class, abbreviation |
| `show-sql` / `hide-sql` | Toggle Mongo command logging |
| `reconnect` / `reconnect!` | Rebuild a dead client, or force a rebuild. Refused while a sandbox is open |
| `redefine` | Reload prefix model files. Refused while a sandbox is open |
| `sandbox-enter` / `sandbox-quit` | Open or abort a transaction on every environment |

## Display

- `record.t` prints one document as a table. `criteria.t` materializes the criteria first.
- Criteria and collection views without your own `limit` are capped at 500 rows (`showing N rows (capped at 500)`).
- `.v` returns table data (`[keys, nil, *rows]`). `.vd` sends rows to visidata.
- `write_csv` and `write_excel` are not capped. `limit` large results yourself.

## SSH

A tunnel forwards a single seed and connects with `direct_connection: true`. `replicaSet` (and other topology options) are stripped. `mongodb+srv` together with `ssh` is rejected.

## Sandbox

Transactions need a replica set or mongos. Model `save` / `update` / `delete` / `create` are intended to run inside that session. A raw `client[:c].insert_one` is not guaranteed to be inside the transaction. `sandbox-quit` aborts; there is no commit.

## Multiple environments

```bash
monq -e a,b
```

A bare top-level constant resolves to the first environment in that list.

## Contributing

Bug reports and pull requests are welcome at https://github.com/lululau/monq. Contributors are expected to follow the [code of conduct](https://github.com/lululau/monq/blob/master/CODE_OF_CONDUCT.md).

## License

MIT. See [LICENSE.txt](LICENSE.txt).
