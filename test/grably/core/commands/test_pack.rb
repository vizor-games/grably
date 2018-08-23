require 'grably'
require 'test/unit'
require 'fileutils'

include Test::Unit
include Grably

class TestPack < TestCase
  def test_zip # rubocop:disable Metrics/MethodLength:
    test_pack do
      pack('test', 'tmp/test.zip', type: :zip)
      unpack('tmp/test.zip', 'tmp/dst', type: :zip)
    end

    test_pack do
      ['zip', '-r', '../test.zip', '.'].run(chdir: 'tmp/src')
      unpack('tmp/test.zip', 'tmp/dst', type: :zip)
    end

    test_pack do
      pack('test', 'tmp/test.zip', type: :zip)
      ['unzip', '../test.zip'].run(chdir: 'tmp/dst')
    end
  end

  def test_tar # rubocop:disable Metrics/MethodLength:
    test_pack do
      pack('test', 'tmp/test.tar', type: :tar)
      unpack('tmp/test.tar', 'tmp/dst', type: :tar)
    end

    test_pack do
      ['tar', '-cf', '../test.tar', '.'].run(chdir: 'tmp/src')
      unpack('tmp/test.tar', 'tmp/dst', type: :tar)
    end

    test_pack do
      pack('test', 'tmp/test.tar', type: :tar)
      ['tar', '-xf', '../test.tar'].run(chdir: 'tmp/dst')
    end
  end

  def test_tar_gz # rubocop:disable Metrics/MethodLength:
    test_pack do
      pack('test', 'tmp/test.tar.gz', type: :tar_gz)
      unpack('tmp/test.tar.gz', 'tmp/dst', type: :tar_gz)
    end

    test_pack do
      ['tar', '-czf', '../test.tar.gz', '.'].run(chdir: 'tmp/src')
      unpack('tmp/test.tar.gz', 'tmp/dst', type: :tar_gz)
    end

    test_pack do
      pack('test', 'tmp/test.tar.gz', type: :tar_gz)
      ['tar', '-xzf', '../test.tar.gz'].run(chdir: 'tmp/dst')
    end
  end

  private

  def test_pack
    prepare
    yield
    compare
    cleanup
  end

  def prepare
    FileUtils.rm_rf('tmp')
    FileUtils.mkdir_p('tmp/dst')
    FileUtils.mkdir_p('tmp/src')
    cp('test', 'tmp/src')
  end

  def cleanup
    FileUtils.rm_rf('tmp')
  end

  def compare # rubocop:disable all
    files_src = Dir.glob_base('**/*', 'tmp/src').sort
    files_dst = Dir.glob_base('**/*', 'tmp/dst').sort
    assert_equal(files_src, files_dst)

    files_src.each do |f|
      f_src = File.join('tmp/src', f)
      f_dst = File.join('tmp/dst', f)
      assert_equal(File.file?(f_src), File.file?(f_dst))
      assert_equal(File.open(f_src, 'rb').read, File.open(f_dst, 'rb').read) if File.file?(f_src)
    end
  end
end
