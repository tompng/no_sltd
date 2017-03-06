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

@result = nil
@requests = []
def recursive &block
  f = Fiber.new &block
  @requests << f
  Fiber.yield :continue
  @result
end


def start &block
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
end

start do
  p hoge 20000
end
p hoge2 20000
