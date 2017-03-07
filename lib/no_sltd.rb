require "no_sltd/version"

module NoSLTD
  CONTINUE = Object.new
  THREAD_LOCAL_KEY = :no_sltd_runner

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

def no_sltd method_or_proc=nil, &block
  raise '`no_sltd def func end`, `block = no_sltd -> {}` or `no_sltd { block.call }`' unless block_given? ^ !!method_or_proc
  if block_given?
    NoSLTD.recursive(&block)
  elsif Proc === method_or_proc
    lambda do |*a, &b|
      NoSLTD.recursive { method_or_proc.call(*a, &b) }
    end
  else
    receiver = respond_to?(:instance_method) ? self : self.class
    original = receiver.instance_method method_or_proc
    receiver.send :remove_method, method_or_proc
    receiver.send :define_method, method_or_proc do |*a, &b|
      NoSLTD.recursive { original.bind(self).call(*a, &b) }
    end
  end
end
