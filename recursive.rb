require 'pry'
def hoge2 i
  return i if i<=1
  hoge2(i-1)+1
end

def hoge i
  return i if i<=1
  a = recursive { hoge i-1 }
  # b = recursive { hoge i-2 }
  # a+b
  a+1
end

def recursive &block
  unless @requests
    return start &block
  end
  f = Fiber.new &block
  @requests << f
  Fiber.yield :continue
  @result
end

def start &block
  @requests = []
  f = Fiber.new{block.call}
  @requests << f
  until @requests.empty? do
    f = @requests.last
    next unless f
    res = f.resume
    if res != :continue
      @result = res
      @requests.pop
    end
  end
  @result
ensure
  @requests = nil
  @result = nil
end

p hoge 20000
p hoge2 20000
