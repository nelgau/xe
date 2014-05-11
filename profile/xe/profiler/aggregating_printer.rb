module Xe
  class Profiler
    # The stanard RubyProf flat printer class considers all fibers to be
    # dinstinct threads. This is related to a hack they comitted back when
    # fibers were first introduced and they have yet to make any attempt
    # to exorcize it. Fibers, like threads, have disinct stacks and are
    # basically the same, right? UGH. This class is a workaround. It
    # aggregates all the fibers together and shows an overall trace.
    class AggregatingPrinter
      attr_reader :result
      attr_reader :min_percent
      attr_reader :total_time
      attr_reader :methods

      # Represents a single method in the source file. It is used to sum the
      # contributions from each thread/fiber.
      class AggregateMethod
        attr_reader :name
        attr_reader :self_percent

        attr_reader :total_time
        attr_reader :self_time
        attr_reader :wait_time
        attr_reader :children_time
        attr_reader :called

        def initialize(name)
          @name = name
          @self_percent = 0
          @total_time = 0
          @self_time = 0
          @wait_time = 0
          @children_time = 0
          @called = 0
        end

        def <<(method)
          @total_time += method.total_time
          @self_time += method.self_time
          @wait_time += method.wait_time
          @children_time += method.children_time
          @called += method.called
        end

        def compute_self_percent(total_time)
          @self_percent = (@self_time / total_time) * 100
        end
      end

      def initialize(result, options={})
        @result = result
        @min_percent = options[:min_percent] || 1.0
        @total_time = 0

        thread_total_times = []
        aggregates = Hash.new do |h, name|
          h[name] = AggregateMethod.new(name)
        end

        @result.threads.each do |thread|
          thread_total_times << thread.total_time
          thread.methods.each do |method|
            aggregates[method.full_name] << method
          end
        end

        @total_time = thread_total_times.max
        @methods = aggregates.values.sort_by(&:self_time).reverse
        @methods.each { |m| m.compute_self_percent(@total_time) }
        @methods.reject! { |m| m.self_percent < @min_percent }
      end

      def print
        # This is basically cribbed from RubyProf's FlatPrinter class with
        # a few, very minor alterations.
        puts " %self      total      self      wait     child    calls  name"
        @methods.each do |m|
          puts "%6.2f  %9.3f %9.3f %9.3f %9.3f %8d  %s" % [
            m.self_percent,
            m.total_time,
            m.self_time,
            m.wait_time,
            m.children_time,
            m.called,
            m.name
          ]
        end
      end

    end
  end
end
