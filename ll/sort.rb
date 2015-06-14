Nil = Object.new
Cons = Struct.new(:h, :t)

def range(from, to)
  if from == to
    Nil
  elsif from < to
    Cons[from, range(from + 1, to)]
  else
    Cons[from, range(from - 1, to)]
  end
end

def foldl(e, xs, &f)
  case xs
  when Cons
    foldl(f[e, xs.h], xs.t, &f)
  when Nil
    e
  end
end

def insert(xs, x)
  case xs
  when Nil
    Cons[x, Nil]
  when Cons
    if x < xs.h
      Cons[x, xs]
    else
      Cons[xs.h, insert(xs.t, x)]
    end
  end
end

def sort(xs)
  foldl(Nil, xs) { |ys, x| insert(ys, x) }
end

puts sort(range(1,101))
