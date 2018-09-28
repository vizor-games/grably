require_relative 'essentials'

module WinPaths # :nodoc:
  def self.unc(path)
    return path unless path.is_a?(String)
    return path if path.start_with?('//?/')
    "//?/#{File.expand_path(path)}"
  end

  def self.uncs(paths)
    paths.map { |p| unc(p) }
  end
end

class IO # :nodoc:
  class << self
    alias _binread binread
    def binread(name, *args)
      _binread(WinPaths.unc(name), *args)
    end

    alias _binwrite binwrite
    def binwrite(name, *args)
      _binwrite(WinPaths.unc(name), *args)
    end

    alias _copy_stream copy_stream
    def copy_stream(src, dst, *args)
      _copy_stream(WinPaths.unc(src), WinPaths.unc(dst), *args)
    end

    # def foreach

    alias _read read
    def read(name, *args)
      _read(WinPaths.unc(name), *args)
    end

    alias _readlines readlines
    def readlines(name, *args)
      _readlines(WinPaths.unc(name), *args)
    end

    alias _write write
    def write(name, *args)
      _write(WinPaths.unc(name), *args)
    end
  end
end

# :nodoc:
# rubocop:disable Metrics/ClassLength
class File
  class << self
    alias _atime atime
    def atime(name)
      _atime(WinPaths.unc(name))
    end

    alias _birthtime birthtime
    def birthtime(name)
      _birthtime(WinPaths.unc(name))
    end

    alias _chmod chmod
    def chmod(mode_int, *names)
      _chmod(mode_int, * WinPaths.uncs(names))
    end

    alias _chown chown
    def chown(owner_int, group_int, *names)
      _chown(owner_int, group_int, * WinPaths.uncs(names))
    end

    alias _ctime ctime
    def ctime(name)
      _ctime(WinPaths.unc(name))
    end

    alias _delete delete
    def delete(*names)
      _delete(* WinPaths.uncs(names))
    end

    alias _directory? directory?
    def directory?(name)
      _directory?(WinPaths.unc(name))
    end

    alias _zero? zero?
    def zero?(name)
      _zero?(WinPaths.uncs(name))
    end

    alias _executable? executable?
    def executable?(name)
      _executable?(WinPaths.unc(name))
    end

    alias _executable_real? executable_real?
    def executable_real?(name)
      _executable_real?(WinPaths.unc(name))
    end

    alias _exist? exist?
    def exist?(name)
      _exist?(WinPaths.unc(name))
    end

    alias _file? file?
    def file?(name)
      _file?(WinPaths.unc(name))
    end

    alias _ftype ftype
    def ftype(name)
      _ftype(WinPaths.unc(name))
    end

    alias _grpowned? grpowned?
    def grpowned?(name)
      _grpowned?(WinPaths.unc(name))
    end

    alias _identical? identical?
    def identical?(name1, name2)
      _identical?(WinPaths.unc(name1), WinPaths.unc(name2))
    end

    alias _lchmod lchmod
    def lchmod(mode_int, *names)
      _lchmod(mode_int, * WinPaths.uncs(names))
    end

    alias _lchown lchown
    def lchown(owner_int, group_int, *names)
      _lchown(owner_int, group_int, * WinPaths.uncs(names))
    end

    alias _link link
    def link(old_name, new_name)
      _link(WinPaths.unc(old_name), WinPaths.unc(new_name))
    end

    alias _lstat lstat
    def lstat(name)
      _lstat(WinPaths.unc(name))
    end

    alias _lutime lutime
    def lutime(atime, mtime, *names)
      _lutime(atime, mtime, * WinPaths.uncs(names))
    end

    alias _mtime mtime
    def mtime(name)
      _mtime(WinPaths.unc(name))
    end

    alias _new new
    def new(name, *args)
      _new(WinPaths.unc(name), *args)
    end

    alias _open open
    def open(name, *args, &block)
      _open(WinPaths.unc(name), *args, &block)
    end

    alias _owned? owned?
    def owned?(name)
      _owned?(WinPaths.unc(name))
    end

    alias _pipe? pipe?
    def pipe?(name)
      _pipe?(WinPaths.unc(name))
    end

    alias _readable? readable?
    def readable?(name)
      _readable?(WinPaths.unc(name))
    end

    alias _readable_real? readable_real?
    def readable_real?(name)
      _readable_real(WinPaths.unc(name))
    end

    alias _realpath realpath
    def realpath(name, *paths)
      _realpath(WinPaths.unc(name), * WinPaths.uncs(paths))
    end

    alias _rename rename
    def rename(old_name, new_name)
      _rename(WinPaths.unc(old_name), WinPaths.unc(new_name))
    end

    alias _size size
    def size(name)
      _size(WinPaths.unc(name))
    end

    alias _size? size?
    def size?(name)
      _size?(WinPaths.unc(name))
    end

    alias _socket? socket?
    def socket?(name)
      _socket?(WinPaths.unc(name))
    end

    alias _stat stat
    def stat(name)
      _stat(WinPaths.unc(name))
    end
  end
end

class Dir # :nodoc:
  class << self
    alias _rmdir rmdir
    def rmdir(name)
      _rmdir(WinPaths.unc(name))
    end
  end
end
