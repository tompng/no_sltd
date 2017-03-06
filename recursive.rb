require 'pry'
require 'benchmark'
module StackLevelSuperdeep
  CONTINUE = Object.new
  THREAD_LOCAL_KEY = :stack_level_superdeep_runner

  class Runner
    attr_reader :result
    def initialize
      @fibers = []
      @stack_level = 0
    end

    def << fiber
      @fibers << fiber
    end

    def start &block
      self << Fiber.new { block.call }
      until @fibers.empty? do
        f = @fibers.last
        next unless f
        res = f.resume
        if res != CONTINUE
          @result = res
          @fibers.pop
        end
      end
      @result
    end

    def direct_callable?
      if @stack_level < 64
        @stack_level += 1
        true
      else
        @stack_level = 0
        false
      end
    end

    def self.execute &block
      runner = Runner.new
      Thread.current.thread_variable_set(THREAD_LOCAL_KEY, runner)
      runner.start &block
    ensure
      Thread.current.thread_variable_set(THREAD_LOCAL_KEY, nil)
    end

    def self.current
      Thread.current.thread_variable_get(THREAD_LOCAL_KEY)
    end
  end

  def self.recursive &block
    runner = Runner.current
    return Runner.execute(&block) unless runner
    return block.call if runner.direct_callable?
    runner << Fiber.new(&block)
    Fiber.yield CONTINUE
    runner.result
  end
end

def recursive &block
  StackLevelSuperdeep.recursive &block
end


# test

def sum_err n
  return 1 if n == 1
  sum_err(n-1) + n
end

def sum_ok n
  return 1 if n == 1
  recursive{sum_ok(n-1)} + n
end

p Benchmark.measure{p sum_err 10000}.real
p Benchmark.measure{p sum_ok 10000}.real
p Benchmark.measure{p sum_ok 40000}.real
#p Benchmark.measure{p sum_err 40000}.real #=> stack level too deep
p Benchmark.measure{p sum_ok 160000}.real

def fib_ok a, memo={0 => 0, 1 => 1}
  return memo[a] if memo[a]
  memo[a-1] ||= recursive { fib_ok a-1, memo }
  memo[a-2] ||= recursive { fib_ok a-2, memo }
  memo[a-1] + memo[a-2]
end

def fib_err a, memo={0 => 0, 1 => 1}
  return memo[a] if memo[a]
  memo[a-1] ||= fib_err a-1, memo
  memo[a-2] ||= fib_err a-2, memo
  memo[a-1] + memo[a-2]
end

raise unless 100.times.all?{|i|fib_ok(i)==fib_err(i)}
p fib_ok(100000).to_s.size #=> 20899
p fib_err(100000) #=> stack level too deep
