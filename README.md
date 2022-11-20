# Redisize

The gem allows to use asynchonous way to cache or just store in redis or any other cache mechanism. For asynchronous caching the Resque or Sidekiq adapters can be used, for synchronous - inline.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redisize'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install redisize

## Usage

### Initialization
Usually adapter can'be defined automatically of presently installed gems. Curretly are supported sidekiq and resque gems to ansyncronous caching (redisizing). If no such gems are installed, the synchronous **inline** adapter is used. You can redefine manually an adapter as follows:

```ruby
Redisize.adapter_kind = :inline
```

Other values are ```:resque```, and ```:sidekiq```.
And then to use the gem just define in the target object:

```ruby
include(Redisize)
```

### In Rails

To use the cache feature with Rails (and ActiveRecord) you have just to wrap a method accessing DB either a record or a relation to a block like this. So to redisize a record value as a json use the follwing:

```ruby
redisize_json(attrs) do
   # <JSON generation code>
   # generate_json(attrs, options)
end
```

to drop a JSON value use:

```ruby
deredisize_json(attrs)
```

to redisize an SQL:

```ruby
redisize_sql do
   relation.as_json(context)
end
```

to redisize an record instance use:

```ruby
redisize_model(slug, by_key: :slug) do
   self.joins(:slug).where(slugs: {text: slug}).first
end
```

Next calls to the block will return a cached value. Updating the record will drop cache for sql or record itself.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/majioa/redisize. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/majioa/redisize/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Redisize project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/majioa/redisize/blob/master/CODE_OF_CONDUCT.md).
