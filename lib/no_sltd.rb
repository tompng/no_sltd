require "no_sltd/version"

module NoSLTD
  THREAD_LOCAL_KEY = :no_sltd_stack_level
  def self.recursive
    level = (Thread.current[THREAD_LOCAL_KEY] || 0)
    Thread.current[THREAD_LOCAL_KEY] = level + 1
    out = level < 64 ? yield : Fiber.new { yield }.resume
    Thread.current[THREAD_LOCAL_KEY] = level
    out
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
