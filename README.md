Simple way to avoid `stack level too deep`

```ruby
x = func a, b, c
# ↓ just wrap it with `recursive { }`
x = recursive { func a, b, c }
```

## examples

```ruby
def sum n
  return 1 if n == 1
  sum(n-1) + n
end
sum 100000 #=> stack level too deep

def sum n
  return 1 if n == 1
  recursive { sum(n-1) } + n
end
sum 100000 #=> 5000050000
```

```ruby
def fib a, memo={0 => 0, 1 => 1}
  return memo[a] if memo[a]
  a1 = fib a-1, memo
  a2 = fib a-2, memo
  memo[a] = a1 + a2
end
fib 100000 #=> stack level too deep

def fib a, memo={0 => 0, 1 => 1}
  return memo[a] if memo[a]
  a1 = recursive { fib a-1, memo }
  a2 = recursive { fib a-2, memo }
  memo[a] = a1 + a2
end
fib 100000 #=> 2597406934722172......
```

## Pros
- easy

## Cons
- memory eater
- slow
