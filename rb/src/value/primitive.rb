require 'value'
require 'evaluator'

module Value
  class Primitive < Fn
    def initialize(param_ts, rest_t, &blk)
      @param_ts = param_ts.map { |t| wrap_type t }
      @rest_t   = wrap_type rest_t
      @blk      = blk

      p, r = parse_params blk.parameters
      self.params = p
      self.rest   = r
    end

    def apply(e, env, args)
      arity_check args
      type_check  args
      Sandbox[e, env]
        .instance_exec(*args, &@blk)
    end

    private
    Sandbox = Struct.new(:evaluator, :env)
    Sandbox.include(Value::Helpers)

    def parse_params(blk_ps)
      p, r = blk_ps.partition { |type, _| :rest != type }
      [p.map { |_, sym| sym }, (r.first || [])[1]]
    end

    def type_check(args)
      args.each_with_index do |v, i|
        ts = typeof(i)
        if ts && ts.all? { |t| !v.is_a?(t) }
          raise Evaluator::TypeError, "Expected instance of "\
                                      "#{ts.join(' or ')}, got #{v}"
        end
      end
    end

    def typeof(i)
      @param_ts[i] || @rest_t
    end

    def wrap_type(t)
      if t
        t.is_a?(Array) ? t : [t]
      end
    end
  end
end
