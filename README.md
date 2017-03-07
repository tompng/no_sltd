# NoSLTD

Simple way to avoid `stack level too deep`

## Installation

```ruby
# Gemfile
gem 'no_sltd', github: 'tompng/no_sltd'
```
<!--
```sh
$ gem install no_sltd
```
-->

## Usage

```ruby
def my_recursive_func
  ...
end
# ↓ just add `no_sltd` before `def`
no_sltd def my_recursive_func
  ...
end
```

or

```ruby
def my_recursive_func
  ...
  my_recursive_func
  ...
end
# wrap the recursive function call with `no_sltd { }`
def my_recursive_func
  ...
  no_sltd { my_recursive_func }
  ...
end
```

### examples

```ruby
def sum_up n
  return 1 if n == 1
  sum_up(n-1) + n
end
sum_up 100000 #=> stack level too deep
# ↓↓↓↓
no_sltd def sum_up n
  return 1 if n == 1
  sum_up(n-1) + n
end
sum_up 100000 #=> 5000050000
```

```ruby
def fibonacci a, memo={0 => 0, 1 => 1}
  return memo[a] if memo[a]
  memo[a] = fibonacci(a-1, memo) + fibonacci(a-2, memo)
end
fibonacci 100000 #=> stack level too deep
# ↓↓↓↓
no_sltd def fibonacci a, memo={0 => 0, 1 => 1}
  return memo[a] if memo[a]
  memo[a] = fibonacci(a-1, memo) + fibonacci(a-2, memo)
end
fibonacci 100000 #=> 2597406934722172......
```

```ruby
fact = lambda do |n|
  n.zero? ? 1 : n * fact.call(n-1)
end
fact.call 10000 #=> stack level too deep

# pass the proc to `no_sltd`
fact = no_sltd ->(n) {
  n.zero? ? 1 : n * fact.call(n-1)
}
fact.call 10000 #=> 2846259680917054......

# or wrap the recursive call with `no_sltd { }`
fact = lambda do |n|
  n.zero? ? 1 : n * no_sltd { fact.call(n-1) }
end
fact.call 10000 #=> 2846259680917054......
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

Bug reports and pull requests are welcome on GitHub at https://github.com/tompng/no_sltd.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
