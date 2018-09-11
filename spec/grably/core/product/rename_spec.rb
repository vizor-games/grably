require 'grably/core/product'

module Grably
  module Core
    describe Product do
      describe '#rename' do
        let(:product) { Product.new('res/ui/img/test.png') }
        let(:renamed) { Product.new('res/ui/img/test.png') }

        context 'when newname given' do
          it { expect(product.rename('test.png')).to eq(renamed) }
        end

        context 'when block is given' do
          it { expect(product.rename(&:downcase)).to eq(renamed) }
        end

        context 'when product has destination directory' do
          it do
            expect(Product.new('a.cpp', 'out/a.cpp').rename('a.o'))
              .to eq(Product.new('a.cpp', 'out/a.o'))
          end
        end
      end
    end
  end
end
