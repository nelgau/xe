require 'spec_helper'

describe Xe::Enumerator::Strategy::Mapper do
  include Xe::Test::Mock::Enumerator::Strategy

  subject do
    Xe::Enumerator::Strategy::Mapper.new(context, enumerable, &map_proc)
  end

  let(:context)    { new_context_mock(&finalize_proc) }
  let(:deferrable) { Xe::Deferrable.new }

  let(:finalize_proc) { Proc.new {} }
  let(:value_proc)    { Proc.new { value } }
  let(:value)         { 4 }

end
