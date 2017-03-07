# StackLevelSuperDeep

Simple way to avoid `stack level too deep`

## Installation

```ruby
# Gemfile
gem 'stack_level_super_deep', github: 'tompng/stack_level_super_deep'
```
<!--
```sh
$ gem install stack_level_super_deep
```
-->

## Usage

```ruby
x = func a, b, c
# ↓ just wrap it with `recursive { }`
x = recursive { func a, b, c }
```

### examples

```ruby
def sumup n
  return 1 if n == 1
  sumup(n-1) + n
end
sumup 100000 #=> stack level too deep
# ↓↓↓↓
def sumup n
  return 1 if n == 1
  recursive { sumup(n-1) } + n
end
sumup 100000 #=> 5000050000
```

```ruby
def fibonacci a, memo={0 => 0, 1 => 1}
  return memo[a] if memo[a]
  a1 = fibonacci a-1, memo
  a2 = fibonacci a-2, memo
  memo[a] = a1 + a2
end
fibonacci 100000 #=> stack level too deep
# ↓↓↓↓
def fibonacci a, memo={0 => 0, 1 => 1}
  return memo[a] if memo[a]
  a1 = recursive { fibonacci a-1, memo }
  a2 = recursive { fibonacci a-2, memo }
  memo[a] = a1 + a2
end
fibonacci 100000 #=> 2597406934722172......
```

### Pros
- simple & easy

### Cons
- memory eater
- slow


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/stack_level_super_deep.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
