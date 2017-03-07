require "stack_level_super_deep/version"

module StackLevelSuperDeep
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
      runner.start(&block)
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
    return yield if runner.direct_callable?
    runner << Fiber.new(&block)
    Fiber.yield CONTINUE
    runner.result
  end
end

def recursive method_or_proc=nil, &block
  raise '`recursive def func end` or `recursive { func }`' unless block_given? ^ !!method_or_proc
  if block_given?
    StackLevelSuperDeep.recursive(&block)
  elsif Proc === method_or_proc
    lambda do |*a, &b|
      StackLevelSuperDeep.recursive { method_or_proc.call(*a, &b) }
    end
  else
    if respond_to? :instance_method
      original = instance_method method_or_proc
      remove_method method_or_proc
      define_method method_or_proc do |*a, &b|
        StackLevelSuperDeep.recursive do
          original.bind(self).call(*a, &b)
        end
      end
    else
      original = method method_or_proc
      eval "undef #{method_or_proc}"
      define_method method_or_proc do |*a, &b|
        StackLevelSuperDeep.recursive do
          original.call(*a, &b)
        end
      end
    end
  end
end
