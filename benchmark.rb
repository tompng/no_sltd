require_relative 'stack_level_superdeep'
require 'pry'
require 'benchmark'

def sum n
  return 1 if n == 1
  sum(n-1) + n
end

def sum_safe n
  return 1 if n == 1
  recursive{sum_safe(n-1)} + n
end

p Benchmark.measure{p sum 10000}.real
p Benchmark.measure{p sum_safe 10000}.real
p Benchmark.measure{p sum_safe 40000}.real
#p Benchmark.measure{p sum 40000}.real #=> stack level too deep
p Benchmark.measure{p sum_safe 160000}.real

def fib_safe a, memo={0 => 0, 1 => 1}
  return memo[a] if memo[a]
  a1 = recursive { fib_safe a-1, memo }
  a2 = recursive { fib_safe a-2, memo }
  memo[a] ||= a1 + a2
end

def fib a, memo={0 => 0, 1 => 1}
  return memo[a] if memo[a]
  a1 = fib a-1, memo
  a2 = fib a-2, memo
  memo[a] ||= a1 + a2
end

raise unless 100.times.all?{|i|fib_safe(i)==fib(i)}
p fib_safe(100000).to_s.size #=> 20899
p fib(100000) #=> stack level too deep
