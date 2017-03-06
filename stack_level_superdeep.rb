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
  memo[a-1] ||= recursive { fib_safe a-1, memo }
  memo[a-2] ||= recursive { fib_safe a-2, memo }
  memo[a-1] + memo[a-2]
end

def fib a, memo={0 => 0, 1 => 1}
  return memo[a] if memo[a]
  memo[a-1] ||= fib a-1, memo
  memo[a-2] ||= fib a-2, memo
  memo[a-1] + memo[a-2]
end

raise unless 100.times.all?{|i|fib_safe(i)==fib(i)}
p fib_safe(100000).to_s.size #=> 20899
p fib(100000) #=> stack level too deep
