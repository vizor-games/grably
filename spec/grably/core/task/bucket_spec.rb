require 'grably/core/task/bucket'
require 'grably/core/product'

class MockRakeApp
  def current_scope; end
end
# Mock object for Bucket tests
class MockTask < Rake::Task
  include Grably::Core::TaskExtensions::Bucket
end

describe Grably::Core::TaskExtensions::Bucket do
  describe '#<<' do
    context 'when expression expands to empty array' do
      let(:t) { MockTask.new(:test, MockRakeApp.new) }
      it 'doesn\'t change the bucket' do
        t << []
        expect(t.bucket).to match_array([])
      end
    end

    let(:t) { MockTask.new(:test, MockRakeApp.new) }

    it 'can be chained' do
      t << Product.new('src', 'dst') << Product.new('src', 'dst')
      expect(t.bucket.length).to eq(2)
    end
  end
end
