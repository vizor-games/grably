require 'grably/core/configuration'

include Grably::Core

describe Configuration do
  describe '::read' do
    SIMPLE_CONFIG = "foo:\n  bar: 42".freeze

    it 'returns object' do
      result = Configuration.read('foo', SIMPLE_CONFIG)
      expect(result).to be_truthy
    end

    describe 'values' do
      it 'generates methods with corresponding names for each value' do
        config = SIMPLE_CONFIG
        result = Configuration.read('foo', config)
        expect(result).to respond_to(:bar).with(0).arguments
      end

      it 'reads simple values into proper types' do
        config = "foo:\n  bar: 42\n  qoo: \"str\"\n  boo: on\n  soo: :sym"
        result = Configuration.read('foo', config)
        expect(result.bar).to eq(42)
        expect(result.qoo).to eq('str')
        expect(result.boo).to eq(true)
        expect(result.soo).to eq(:sym)
      end

      it 'reads complex values into proper types' do
        config = "foo:\n  bar: [1, 2, 3]\n  qoo:\n    foo: 42"
        result = Configuration.read('foo', config)
        expect(result.bar).to match_array([1, 2, 3])
        expect(result.qoo).to eq('foo' => 42)
      end

      it 'evaluates \#{...} inside string literals' do
        config = "foo:\n  v: '\#{2 + 2}'"
        result = Configuration.read('foo', config)
        expect(result.v).to eq('4')
      end

      it 'allow refer profile values inside evaluations' do
        config = "foo:\n  a: 1\n  b: '\#{c.a}'"
        result = Configuration.read('foo', config)
        expect(result.b).to eq('1')
      end

      it 'evaluates \#{...} inside nested hashes and arrays' do
        config = "foo:\n  a: [ '#{2 + 2}' ]"
        result = Configuration.read('foo', config)
        expect(result.a).to match_array(%w(4))

        config = "foo:\n a:\n    b: '#{2 + 2}'"
        result = Configuration.read('foo', config)
        expect(result.a).to eq('b' => '4')
      end
    end

    describe 'profiles' do
      it 'always contains `default` profile' do
        expect(Configuration.read('default')).to be_truthy
      end

      it 'contains `profile` field which stands for current profile' do
        expect(Configuration.read('foo', "foo:\n  x: 2").profile).to match_array(%w(foo))
      end

      it 'returns `default` profile if no profile requested' do
        expect(Configuration.read([], "default:\n  foo: 2").profile).to match_array(%w(default))
      end

      it 'reads profile as first level key' do
        config = SIMPLE_CONFIG
        result = Configuration.read('foo', config)
        expect(result).to be_truthy

        expect { Configuration.read('bar', config) }.to raise_error(ArgumentError)
      end

      it 'merge repeated profile definitions' do
        config = "foo:\n  a: 2\nfoo:\n  b: 3"
        result = Configuration.read('foo', config)
        expect(result.a).to eq(2)
        expect(result.b).to eq(3)
      end

      it 'allows regexps as profile names' do
        config = "/final-(.+?)-([0-9]+)/:\n  server: 'zf-\#{c.captures[0]}-\#{c.captures[1]}'"
        result = Configuration.read('final-vk-1', config)
        expect(result.server).to eq('zf-vk-1')
      end
    end

    describe '`extends` key' do
      it 'merges listed profiles into declaring profile' do
        config = "a:\n  extends: [b, c]\nb:\n  a: 1\nc:\n  b: 2"
        result = Configuration.read('a', config)

        expect(result.extends).to match_array(%w(b c))
        expect(result.a).to eq(1)
        expect(result.b).to eq(2)
      end

      it 'fails when hits missing profile' do
        config = "a:\n extends: [ b ]"
        expect { Configuration.read('a', config) }.to raise_error(ArgumentError)
      end

      it 'fails when hits cyclic dependency' do
        config = "a:\n extends: [ b ]\nb:\n  extends: [ c ]\nc:\n  extends: [ a ]"
        expect { Configuration.read('a', config) }.to raise_error(ArgumentError)
      end

      it 'allows single value' do
        config = "a:\n  extends: b\nb:\n  a: 1"
        result = Configuration.read('a', config)
        expect(result.a).to eq(1)
      end
    end

    describe 'streams' do
      it 'allows anonymous streams' do
        expect { Configuration.read('foo', SIMPLE_CONFIG) }.not_to raise_error
      end

      it 'merges config from multiple streams' do
        s1 = "foo:\n  a: 1\n  b: 2"
        s2 = "foo:\n  b: 3\n  c: 4"

        result = Configuration.read('foo', s1, s2)
        expect(result.a).to eq(1)
        expect(result.b).to eq(3)
        expect(result.c).to eq(4)
      end
    end
  end

  describe '::load' do
    before(:all) do
      @working_dir = Dir.mktmpdir
      main = <<-YML.strip_indent
      foo:
        bar: 1
      YML

      user = <<-YML.strip_indent
      foo:
        baz: 2
      YML

      override = <<-YML.strip_indent
      foo:
        qoo: 3
      YML

      Configuration::CONFIGURATION_FILES.zip([main, user, override]).each do |name, content|
        IO.write(File.join(@working_dir, name), content)
      end
    end

    let(:config) { Configuration.load(%w(foo), dir: @working_dir) }

    it 'creates configuration object for requested profile' do
      expect(config.bar).to eq(1)
      expect(config.baz).to eq(2)
      expect(config.qoo).to eq(3)
    end

    after(:all) do
      FileUtils.remove_entry(@working_dir)
    end
  end
end
