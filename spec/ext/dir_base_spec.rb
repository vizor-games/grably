# NOTICE: This file contains adopted version of tests used in ruby for
#         Dir.glob with base: argument.
#         Original source code: https://github.com/ruby/ruby/blob/58f2e6b/test/ruby/test_dir.rb
require 'ext/dir'
require 'tmpdir'
require 'fileutils'

describe Dir do
  describe '::glob_base_pre25' do
    before(:all) do
      @root = File.realpath(Dir.mktmpdir('__test_dir__'))
      @nodir = File.join(@root, 'dummy')
      @dirs = []
      ('a'..'z').each do |i|
        if i.ord.even?
          FileUtils.touch(File.join(@root, i))
        else
          FileUtils.mkdir(File.join(@root, i))
          @dirs << File.join(i, '')
        end
      end
    end

    context do
      before(:all) do
        @files = %w(a/foo.c c/bar.c)
        @files.each { |n| File.write(File.join(@root, n), '') }
        Dir.mkdir(File.join(@root, 'a/dir2'))
      end

      let!(:ctx_dirs) { (@dirs + %w(a/dir2/)).sort }

      it { expect(Dir.glob_base_pre25('*/*.c', @root).sort).to eq(@files) }
      it { expect(Dir.chdir(@root) { Dir.glob_base_pre25('*/*.c', '.').sort }).to eq(@files) }
      it { expect(Dir.chdir(@root) { Dir.glob_base_pre25('*.c', 'a').sort }).to eq(%w(foo.c)) }
      it { expect(Dir.chdir(@root) { Dir.glob_base_pre25('*/*.c', '').sort }).to eq(@files) }
      it { expect(Dir.chdir(@root) { Dir.glob_base_pre25('*/*.c', nil).sort }).to eq(@files) }
      it { expect(Dir.glob_base_pre25('*/', @root).sort).to eq(@dirs) }
      it { expect(Dir.chdir(@root) { Dir.glob_base_pre25('*/', '.').sort }).to eq(@dirs) }
      it { expect(Dir.chdir(@root) { Dir.glob_base_pre25('*/', 'a').sort }).to eq(%w(dir2/)) }
      it { expect(Dir.chdir(@root) { Dir.glob_base_pre25('*/', '').sort }).to eq(@dirs) }
      it { expect(Dir.chdir(@root) { Dir.glob_base_pre25('*/', nil).sort }).to eq(@dirs) }
      it { expect(Dir.glob_base_pre25('**/*/', @root).sort).to eq(ctx_dirs) }
      it { expect(Dir.chdir(@root) { Dir.glob_base_pre25('**/*/', '.').sort }).to eq(ctx_dirs) }
      it { expect(Dir.chdir(@root) { Dir.glob_base_pre25('**/*/', 'a').sort }).to eq(%w(dir2/)) }
      it { expect(Dir.chdir(@root) { Dir.glob_base_pre25('**/*/', '').sort }).to eq(ctx_dirs) }
      it { expect(Dir.chdir(@root) { Dir.glob_base_pre25('**/*/', nil).sort }).to eq(ctx_dirs) }

      after(:all) { FileUtils.rm_rf(File.join(@root, 'a/dir2')) }
    end

    context do
      before(:all) do
        @files = %w(a/foo.c c/bar.c)
        @files.each { |n| File.write(File.join(@root, n), '') }
        Dir.mkdir(File.join(@root, 'a/dir'))
      end

      let!(:files) { @files }
      let!(:dirs) { (@dirs + %w(a/dir/)).sort }
      it { expect(Dir.open(@root) { |d| Dir.glob_base_pre25('*/*.c', d) }.sort).to eq(files) }
      it { expect(Dir.chdir(@root) { Dir.open('a') { |d| Dir.glob_base_pre25('*.c', d) } }).to eq(%w(foo.c)) }
      it { expect(Dir.open(@root) { |d| Dir.glob_base_pre25('*/', d).sort }).to eq(@dirs) }
      it { expect(Dir.chdir(@root) { Dir.open('a') { |d| Dir.glob_base_pre25('*/', d).sort } }).to eq(%w(dir/)) }
      it { expect(Dir.open(@root) { |d| Dir.glob_base_pre25('**/*/', d).sort }).to eq(dirs) }
      it { expect(Dir.chdir(@root) { Dir.open('a') { |d| Dir.glob_base_pre25('**/*/', d).sort } }).to eq(%w(dir/)) }

      after(:all) { FileUtils.rm_rf(File.join(@root, 'a/dir')) }
    end

    after(:all) do
      FileUtils.rm_rf(@root)
    end
  end
end
