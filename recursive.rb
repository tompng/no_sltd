require 'pry'

module StackLevelSuperdeep
  CONTINUE = Object.new
  THREAD_LOCAL_KEY = :stack_level_superdeep_runner
  class Runner
    attr_reader :result
    def initialize
      @fibers = []
    end

    def << fiber
      @fibers << fiber
    end

    def start &block
      f = Fiber.new { block.call }
      self << f
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

    def self.execute &block
      runner = Runner.new
      Thread.current[THREAD_LOCAL_KEY] = runner
      runner.start &block
    ensure
      Thread.current[THREAD_LOCAL_KEY] = nil
    end

    def self.current
      Thread.current[THREAD_LOCAL_KEY]
    end
  end

  def self.recursive &block
    return Runner.execute(&block) unless Runner.current
    Runner.current << Fiber.new(&block)
    Fiber.yield CONTINUE
    Runner.current.result
  end
end

def recursive &block
  StackLevelSuperdeep.recursive &block
end

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
p fib_ok(10000).to_s.size #=> 2090
p fib_err(10000) #=> stack level too deep
