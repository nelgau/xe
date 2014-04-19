RSpec::Matchers.define :be_collected do
  match do |mod|
    ObjectSpace.each_object(mod).count == 0
  end
end
