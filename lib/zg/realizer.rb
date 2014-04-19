module Zg
  class Realizer
    # Class interface.
    def self.call(ids); self.new.run(ids);  end
    def self.[](id);    Zg.defer(self, id); end

    # Returns a proxy that represents a single id
    def [](id)
      Zg.defer(self, id)
    end

    # Override this method to provide a bulk loader.
    def call(ids)
      raise NotImplementedError
    end
  end
end
