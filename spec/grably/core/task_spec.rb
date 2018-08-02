require 'grably/core'

describe Grably::Core::Task do
  it('is Rake::Task') { expect(Grably::Core::Task).to eq(Rake::Task) }
end
