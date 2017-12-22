[![Gem Version](https://badge.fury.io/rb/ass_ole-snippets-shared.svg)](https://badge.fury.io/rb/ass_ole-snippets-shared)
# AssOle::Snippets::Shared

Shared ole snippets for [ass_ole](https://github.com/leoniv/ass_ole)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ass_ole-snippets-shared'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ass_ole-snippets-shared

## Example

```ruby
require 'ass_ole'
require 'ass_ole/snippets/shared'
require 'ass_maintainer/info_base'

# External connection runtime
module ExternalRuntime
  is_ole_runtime :external
end

class Worker
  like_ole_runtime ExternalRuntime
  include AssOle::Snippets::Shared::Query

  def initialize(connection_string)
    ole_runtime_get.run AssMaintainer::InfoBase.new('ib_name', connection_string)
  end

  def select(value)
    query('select &arg as arg', arg: value).Execute.Unload.Get(0).arg
  end
end

Worker.new('File="path"').select('Hello') #=> "Hello"
```

## Testing

    $ export SIMPLECOV=YES && rake test

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/leoniv/ass_ole-snippets-shared.

