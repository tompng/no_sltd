require 'test_helper'

class StackLevelSuperDeepTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::StackLevelSuperDeep::VERSION
  end

  module Fibonacci
    def self.fibonacci_memo i, memo={0 => 0, 1 => 1}
      return memo[i] if memo[i]
      a = recursive { fibonacci_memo i-1, memo }
      b = recursive { fibonacci_memo i-2, memo }
      memo[i] = a + b
    end

    def self.fibonacci i
      return i if i <= 1
      recursive { fibonacci(i-1) } + recursive { fibonacci(i-2) }
    end
  end

  def test_fibonacci
    correct = [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
    assert correct == correct.size.times.map { |i| Fibonacci.fibonacci(i) }
    assert correct == correct.size.times.map { |i| Fibonacci.fibonacci_memo(i) }
  end

  def test_fibonacci_stack
    n = 100000
    fibo = Fibonacci.fibonacci_memo(n)
    fibo_log = Math.log(fibo)
    a, b = (1+Math.sqrt(5))/2, (1-Math.sqrt(5))/2
    true_fibo_log = n*Math.log(a) + Math.log(1-(b/a)**n) - Math.log(5)/2
    diff = 1e-8
    assert (1-diff..1+diff).include?(fibo_log/true_fibo_log)
  end

  def test_sumup
    def sumup_safe i
      return 0 if i.zero?
      recursive { sumup_safe(i-1) } + i
    end
    def sumup n
      code = %(def sumup i; return 0 if i.zero?; sumup(i-1) + i; end)
      `ruby -e "#{code};p sumup(#{n})" 2>&1`
    end
    [10, 100, 1000].each do |i|
      assert sumup(i).to_i == i*(i+1)/2
      assert sumup_safe(i) == i*(i+1)/2
    end
    n = 100000
    assert sumup_safe(n) == 5000050000
    assert sumup(n) =~ /SystemStackError/
  end
end
