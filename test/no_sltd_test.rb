require 'test_helper'

class NoSLTDTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::NoSLTD::VERSION
  end

  def fibonacci_memo i, memo={0 => 0, 1 => 1}
    return memo[i] if memo[i]
    a = no_sltd { fibonacci_memo i-1, memo }
    b = no_sltd { fibonacci_memo i-2, memo }
    memo[i] = a + b
  end

  no_sltd def fibonacci_memo2 i, memo={0 => 0, 1 => 1}
    return memo[i] if memo[i]
    memo[i] = fibonacci_memo2(i-1, memo) + fibonacci_memo2(i-2, memo)
  end

  def fibonacci i
    return i if i <= 1
    no_sltd { fibonacci(i-1) } + no_sltd { fibonacci(i-2) }
  end

  def test_fibonacci
    correct = [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
    assert correct == correct.size.times.map { |i| fibonacci(i) }
    assert correct == correct.size.times.map { |i| fibonacci_memo(i) }
    assert correct == correct.size.times.map { |i| fibonacci_memo2(i) }
  end

  def test_fibonacci_stack
    n = 100000
    fibo = fibonacci_memo n
    fibo2 = fibonacci_memo2 n
    assert fibo == fibo2
    fibo_log = Math.log(fibo)
    a, b = (1+Math.sqrt(5))/2, (1-Math.sqrt(5))/2
    true_fibo_log = n*Math.log(a) + Math.log(1-(b/a)**n) - Math.log(5)/2
    diff = 1e-8
    assert (1-diff..1+diff).include?(fibo_log/true_fibo_log)
  end

  def sum_up_safe i
    return 0 if i.zero?
    no_sltd { sum_up_safe(i-1) } + i
  end

  no_sltd def sum_up_safe2 i
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
    code = %(->(n){n.zero? ? 0 : n+sum_up.call(n-1)})
    sum_up = no_sltd eval(code)
    assert (1..5).map { |i| sum_up.call i } == [1, 3, 6, 10, 15]
    assert !!sum_up.call(100000)
    assert `ruby -e "sum_up=#{code};sum_up[100000]" 2>&1` =~ /SystemStackError/
  end

  def test_zigzag
    no_sltd def zig n
      n.zero? ? 0 : zag(n-1)+2
    end

    no_sltd def zag n
      n.zero? ? 0 : zig(n-1)+1
    end

    assert 10.times.map{|i|zig i} == [0,2,3,5,6,8,9,11,12,14]
    assert !!zig(100000)
  end
end
