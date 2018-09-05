require 'grably/core/product'

module Grably
  module Core
    module ProductExpand
      describe ProductExpand do
        describe 'product filter sring format' do
          let(:parse) { ->(f) { ProductExpand.parse_string_filter(f) } }

          it { expect(parse.call('**/*')).to match_array [nil, nil, '**/*'] }
          it { expect(parse.call('old_base:**/*')).to match_array [nil, 'old_base', '**/*'] }
          it { expect(parse.call('new_base::**/*')).to match_array ['new_base', nil, '**/*'] }
          it do
            filter = 'new_base/foo:old_base/bar:files/*.{xml,yml,json}'
            unpacked = ['new_base/foo', 'old_base/bar', 'files/*.{xml,yml,json}']
            expect(parse.call(filter)).to match_array(unpacked)
          end
        end

        describe 'expanding filtering products' do
          let(:products) do
            %w(xml/foo.xml bar/1.json bar2.json png/foo.png bar/one.json)
              .map { |f| Product.new(f, f) }.freeze
          end

          context 'filtering products matches glob patterns' do
            it do
              expect(Product.expand(products => 'jpeg/**')).to be_empty
            end
            it do
              expect(Product.expand(products => '**/*.xml').map(&:dst))
                .to match_array %w(xml/foo.xml)
            end
          end

          context 'product filter can be negated' do
            it do
              expect(Product.expand(products => '!**/*.json').map(&:dst))
                .to match_array %w(xml/foo.xml png/foo.png)
            end
          end

          context 'filter can be used to remove destination base path' do
            it do
              expect(Product.expand(products => 'png:**/*').map(&:dst))
                .to match_array %w(foo.png)
            end
          end

          context 'filter can be used to prepend destination base path' do
            it do
              expect(Product.expand(products => 'json::**/one.json').map(&:dst))
                .to match_array %w(json/bar/one.json)
            end
          end

          context 'fiter can be used to move desitnation to another directory' do
            it do
              expect(Product.expand(products => 'json:bar:**/*').map(&:dst))
                .to match_array %w(json/one.json json/1.json)
            end
          end
        end
      end
    end
  end
end
