require 'rspec'
require 'fileutils'
require 'tmpdir'
require 'grably'
require 'digest'

module PackTest
  def scan_files(base)
    files = Dir.glob_base('**/*', base)
    m = {}
    files.each do |f|
      ff = File.join(base, f)
      if File.file?(ff)
        m[f] = [File.size(ff), Digest::SHA256.digest(IO.read(ff))]
      end
    end
    m
  end

  def arc_name(suffix)
    Dir.glob(File.join(@tmp_dir, 'a.*')) do |f|
      FileUtils.rm(f)
    end
    File.join(@tmp_dir, "a.#{suffix}")
  end

  def do_setup
    @tmp_dir = Dir.mktmpdir
    @src_dir = File.join(@tmp_dir, 'src')
    @dst_dir = File.join(@tmp_dir, 'dst')
    FileUtils.mkdir_p(@src_dir)
    cp('test', @src_dir)
    @src_files = scan_files(@src_dir)
  end

  def do_prepare
    FileUtils.rm_rf(@dst_dir)
    FileUtils.mkdir_p(@dst_dir)
  end

  def do_finish
    FileUtils.rm_rf(@tmp_dir)
  end
end

describe Grably, '.pack' do
  include PackTest

  context 'should detect archive type' do
    it 'should detect zip' do
      expect(Grably::Compress.autodetect_archive_type('a.zip')).to be(:zip)
    end

    it 'should detect tar' do
      expect(Grably::Compress.autodetect_archive_type('a.tar')).to be(:tar)
    end

    it 'should detect tar.gz' do
      expect(Grably::Compress.autodetect_archive_type('a.tar.gz')).to be(:tar_gz)
    end
  end

  context 'should pack/unpack the same way as standard tools' do
    before(:all) do
      do_setup
    end

    before(:each) do
      do_prepare
    end

    it 'should pack/unpack zip itself' do
      arc = arc_name('zip')
      pack(@src_dir, arc)
      unpack(arc, @dst_dir)
      expect(scan_files(@dst_dir)).to eql(@src_files)
    end

    it 'should pack zip itself and unpack with standard tool' do
      arc = arc_name('zip')
      pack(@src_dir, arc)
      ['unzip', arc].run(chdir: @dst_dir)
      expect(scan_files(@dst_dir)).to eql(@src_files)
    end

    it 'should pack zip with standard tool and unpack itself' do
      arc = arc_name('zip')
      ['zip', '-r', arc, '.'].run(chdir: @src_dir)
      unpack(arc, @dst_dir)
      expect(scan_files(@dst_dir)).to eql(@src_files)
    end

    it 'should pack/unpack tar itself' do
      arc = arc_name('tar')
      pack(@src_dir, arc)
      unpack(arc, @dst_dir)
      expect(scan_files(@dst_dir)).to eql(@src_files)
    end

    it 'should pack tar itself and unpack with standard tool' do
      arc = arc_name('tar')
      pack(@src_dir, arc)
      ['tar', '-xf', arc].run(chdir: @dst_dir)
      expect(scan_files(@dst_dir)).to eql(@src_files)
    end

    it 'should pack tar with standard tool and unpack itself' do
      arc = arc_name('tar')
      ['tar', '-cf', arc, '.'].run(chdir: @src_dir)
      unpack(arc, @dst_dir)
      expect(scan_files(@dst_dir)).to eql(@src_files)
    end

    it 'should pack/unpack tar.gz itself' do
      arc = arc_name('tar.gz')
      pack(@src_dir, arc)
      unpack(arc, @dst_dir)
      expect(scan_files(@dst_dir)).to eql(@src_files)
    end

    it 'should pack tar itself and unpack with standard tool' do
      arc = arc_name('tar.gz')
      pack(@src_dir, arc)
      ['tar', '-xzf', arc].run(chdir: @dst_dir)
      expect(scan_files(@dst_dir)).to eql(@src_files)
    end

    it 'should pack tar with standard tool and unpack itself' do
      arc = arc_name('tar.gz')
      ['tar', '-czf', arc, '.'].run(chdir: @src_dir)
      unpack(arc, @dst_dir)
      expect(scan_files(@dst_dir)).to eql(@src_files)
    end

    after(:all) do
      do_finish
    end
  end
end
