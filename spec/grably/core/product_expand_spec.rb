require 'rspec'
require 'grably/core/product'

include Grably::Core

describe 'Product.expand(..)' do
  it 'should expand array of products to same array' do
    products = [Product.new('src/foo.json'), Product.new('src/bar.json')]
    expect(ProductExpand.expand(products)).to eq(products)
  end

  it 'should expand empty array to empty array' do
    expect(ProductExpand.expand([])).to eq([])
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
        expect(ProductExpand.expand(['src'])).to match_array(products)
      end
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

  it 'should be flatmap operation' do
    expect(Product.expand([[[[[[Product.new('foo.json')]]]]]])).to eq([Product.new('foo.json')])
  end

  it 'should expand hash as expr => filter' do
    files = %w(src/foo.json src/bar.json)
    products = files.map { |f| Product.new(f, f) }
    expected = files.map { |f| Product.new(f, File.join('dst', File.split(f).last)) }
    expanded = ProductExpand.expand(products => 'dst:src:**/*')
    expect(expanded).to eq(expected)
  end

  it 'should expand hash with proc as filter' do
    products = [Product.new('src/foo.json'), Product.new('src/bar.txt')]
    # Update meta with file extension
    update_meta = ->(p) { p.update(ext: File.basename(p.dst).split('.').last) }
    expanded = ProductExpand.expand(products => ->(o, _expand) { o.map(&update_meta) })
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
