require 'grably/core/product'

module Grably
  module Core
    describe 'File extension checks' do
      let(:product) { Product.new('test.png') }
      context 'when file ends with matching file extension' do
        it { expect(product.png?).to be_truthy }
      end

      context 'when filed ends with other extesion' do
        it { expect(product.jpeg?).to be_falsey }
      end
    end
  end
end
