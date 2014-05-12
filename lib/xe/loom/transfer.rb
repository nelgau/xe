module Xe
  module Loom
    # This implementation takes into account the possibility that the body of
    # an enumeration or realizer may itself use fibers to implement another
    # layer of cooperative concurrency. It explicitly transfers control between
    # managed fibers instead of using resume/yield.
    #
    # *** NOTE: While superficially correct, the candidate implementation that
    # I explored segfaults on Ruby 1.9.3-p448 when an exception is thrown from
    # a fiber into which control has been transferred. It seemed like the
    # problem was quite deep in MRI and not worth further investigation.
    class Transfer < Base
      # Left blank for now.
    end
  end
end
