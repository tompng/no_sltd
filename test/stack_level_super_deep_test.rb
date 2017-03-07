require 'test_helper'

class StackLevelSuperDeepTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::StackLevelSuperDeep::VERSION
  end

  def fibonacci_memo i, memo={0 => 0, 1 => 1}
    return memo[i] if memo[i]
    a = recursive { fibonacci_memo i-1, memo }
    b = recursive { fibonacci_memo i-2, memo }
    memo[i] = a + b
  end

  recursive def fibonacci_memo2 i, memo={0 => 0, 1 => 1}
    return memo[i] if memo[i]
    memo[i] = fibonacci_memo2(i-1, memo) + fibonacci_memo2(i-2, memo)
  end

  def fibonacci i
    return i if i <= 1
    recursive { fibonacci(i-1) } + recursive { fibonacci(i-2) }
  end

  def test_fibonacci
    correct = [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
    assert correct == correct.size.times.map { |i| fibonacci(i) }
    assert correct == correct.size.times.map { |i| fibonacci_memo(i) }
    assert correct == correct.size.times.map { |i| fibonacci_memo2(i) }
  end

  def test_recursive_method_and_block
    n = 100000
    assert fibonacci_memo(n) == fibonacci_memo2(n)
  end

  def test_fibonacci_stack
    n = 100000
    fibo = fibonacci_memo(n)
    fibo_log = Math.log(fibo)
    a, b = (1+Math.sqrt(5))/2, (1-Math.sqrt(5))/2
    true_fibo_log = n*Math.log(a) + Math.log(1-(b/a)**n) - Math.log(5)/2
    diff = 1e-8
    assert (1-diff..1+diff).include?(fibo_log/true_fibo_log)
  end

  def sum_up_safe i
    return 0 if i.zero?
    recursive { sum_up_safe(i-1) } + i
  end

  recursive def sum_up_safe2 i
    return 0 if i.zero?
    sum_up_safe(i-1) + i
  end

  def sum_up n
    code = %(def sum_up i; return 0 if i.zero?; sum_up(i-1) + i; end)
    `ruby -e "#{code};p sum_up(#{n})" 2>&1`
  end

  def test_sum_up
    [10, 100, 1000].each do |i|
      assert sum_up(i).to_i == i*(i+1)/2
      assert sum_up_safe(i) == i*(i+1)/2
      assert sum_up_safe2(i) == i*(i+1)/2
    end
    n = 100000
    assert sum_up_safe(n) == 5000050000
    assert sum_up_safe2(n) == 5000050000
    assert sum_up(n) =~ /SystemStackError/
  end

  def test_lambda
    code = %(->(n){n.zero? ? 1 : n*fact.call(n-1)})
    fact = recursive eval(code)
    assert (1..5).map { |i| fact.call i } == [1, 2, 6, 24, 120]
    assert !!fact.call(10000)
    assert `ruby -e "fact=#{code};fact[10000]" 2>&1` =~ /SystemStackError/
  end
end
