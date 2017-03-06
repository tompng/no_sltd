require 'pry'
def hoge2 i
  return i if i<=1
  hoge2(i-1)+1
end

def hoge i
  return i if i<=1
  a = request i-1
  # p i, a
  # request i-2
  # Fiber.yield :continue
  # b = get
  # p [a,b]
  a+1
end

@result = nil
@requests = []
def request a
  f = Fiber.new{
    hoge a
  }
  @requests << f
  Fiber.yield :continue
  @result
end


def start &block
  f = Fiber.new{block.call}
  @requests << f
  until @requests.empty? do
    # i = @requests.size-1
    f = @requests.last
    next unless f
    res = f.resume
    if res == :continue

    else
      @result = res
      @requests.pop
    end
  end
end

start do
  p hoge 20000
end
p hoge2 20000
