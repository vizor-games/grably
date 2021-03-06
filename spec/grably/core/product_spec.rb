require 'grably/core/product'

module Grably
  module Core
    describe Product do
      describe '::expand' do
        it 'should expand array of products to same array' do
          products = [Product.new('src/foo.json'), Product.new('src/bar.json')]
          expect(Product.expand(products)).to eq(products)
        end

        it 'should expand empty array to empty array' do
          expect(Product.expand([])).to eq([])
        end

        context 'expand dir as list of products' do
          before do
            @wd = Dir.mktmpdir
            FileUtils.mkdir(File.join(@wd, 'src'))
            files = %w(src/foo.json)
            files.each { |f| FileUtils.touch(File.join(@wd, f)) }
          end

          it do
            Dir.chdir(@wd) do
              products = [Product.new('src/foo.json')]
              expect(Product.expand('src')).to match_array(products)
            end
          end

          it do
            products = [Product.new(File.join(@wd, 'src/foo.json'), 'foo.json')]
            expect(Product.expand('src/foo.json', base_dir: @wd))
              .to match_array(products)
          end

          it do
            products = [Product.new(File.join(@wd, 'src/foo.json'))]
            expect(Product.expand('src', base_dir: @wd))
              .to match_array(products)
          end

          after do
            FileUtils.remove_entry(@wd)
          end
        end

        context 'when directory contains sub dirs' do
          before do
            @wd = Dir.mktmpdir
            %w(src/foo src/bar src/qoo).each do |d|
              FileUtils.mkdir_p(File.join(@wd, d))
            end
          end

          it do
            expect(Product.expand(@wd)).to be_empty
          end
        end

        context 'context array may be expanded using filter' do
          files = %w(lib/open.rb lib/close.rb spec/open_spec.rb spec/close_spec.rb)

          before(:all) do
            @tmpdir = Dir.mktmpdir
            files
              .map { |f| File.join(@tmpdir, f) }
              .each { |f| FileUtils.mkdir_p(File.dirname(f)) }
              .each { |f| FileUtils.touch(f) }
          end

          it do
            expect(Product.expand(Dir["#{@tmpdir}/*"] => 'open*.rb').map(&:dst))
              .to match_array %w(open.rb open_spec.rb)
          end

          it do
            expect(Product.expand(Dir["#{@tmpdir}/*"] => '!close*.rb').map(&:dst))
              .to match_array %w(open.rb open_spec.rb)
          end

          after(:all) do
            FileUtils.rm_rf(@tmpdir)
          end
        end

        it 'should be flatmap operation' do
          expect(Product.expand([[[[[[Product.new('foo.json')]]]]]])).to eq([Product.new('foo.json')])
        end

        it 'should expand hash as expr => filter' do
          files = %w(src/foo.json src/bar.json)
          products = files.map { |f| Product.new(f, f) }
          expected = files.map { |f| Product.new(f, File.join('dst', File.split(f).last)) }
          expanded = Product.expand(products => 'dst:src:**/*')
          expect(expanded).to eq(expected)
        end

        it 'should expand hash with proc as filter' do
          products = [Product.new('src/foo.json'), Product.new('src/bar.txt')]
          # Update meta with file extension
          expanded = Product.expand(products => ->(s, d, m) { [s, d, m.merge(ext: File.basename(d).split('.').last)] })
          expect(expanded.map { |p| p[:ext] }).to eq(%w(json txt))
        end

        context 'expanding Task by name' do
          let(:app) { double }
          let(:product) { Product.new('src/test.txt') }
          let(:task) { Task.new(:foo, app) << product }

          before do
            allow(app).to receive(:current_scope)
          end

          it 'should return Task bucket' do
            allow(Rake).to receive(:application).and_return(foo: task)
            context = double
            allow(context).to receive(:all_prerequisite_tasks).and_return([task])
            expect(Product.expand(:foo, context)).to match_array([product])
          end

          it 'should ignore provided options' do
            allow(Rake).to receive(:application).and_return(foo: task)
            context = double
            allow(context).to receive(:all_prerequisite_tasks).and_return([task])
            expect(Product.expand(:foo, context, base_dir: '/tmp'))
              .to match_array([product])
          end

          context 'when trying expand missing dependency' do
            it 'should raise exception' do
              bar = Task.new(:bar, app)
              allow(Rake).to receive(:application).and_return(foo: task, bar: bar)
              expect { Product.expand(:bar, task) }
                .to raise_error(ArgumentError)
            end
          end
        end
      end

      describe '::with_meta' do
        let(:product) { Product.new('a.cpp') }
        it 'adds values to product meta' do
          expect(Product.with_meta!(product, foo: 42))
            .to match_array([product.update(foo: 42)])
        end

        context 'when product has meta values' do
          let(:product) { Product.new('a.cpp', 'a.cpp', foo: 42) }
          it 'merges two hashes' do
            expect(Product.with_meta!(product, bar: 1))
              .to match_array([product.update(foo: 42)])
          end
        end
      end

      describe '#eql?' do
        context 'when two products have same src and dst but different meta' do
          let(:a) { Product.new('foo.txt', 'foo.txt', foo: 'bar') }
          let(:b) { Product.new('foo.txt', 'foo.txt', bar: 'bar') }

          it { expect(a).to eq(b) }
          it { expect(a).to eql(b) }
          it { expect(a).not_to equal(b) }
        end
      end

      describe 'grab meta fields' do
        let(:product) { Product.new('a.png', 'a.png', quality: 90, format: :webp) }

        it { expect(product[:quality]).to eq(90) }
        it { expect(product[:quality, :format]).to match_array([90, :webp]) }
      end

      describe '#update' do
        let(:product) { Product.new('file.txt') }

        it { expect(product.update(foo: 42)).to eq(product) }
        it { expect(product.update(foo: 42)).not_to be(product) }
        it { expect { product.update(foo: 42) }.not_to change(product, :meta) }
      end

      describe 'Array include?' do
        let(:product) { Product.new('file.txt') }

        it { expect([Product.new('a.txt')]).to include(Product.new('a.txt')) }
      end

      describe '#meta' do
        let(:product) { Product.new('file.txt', 'file.txt', foo: 42, qoo: 1) }

        it { expect(product.meta).to eq(foo: 42, qoo: 1) }
      end
    end
  end
end
