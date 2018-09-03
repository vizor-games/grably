module Grably
  module ProductRename # :nodoc:
    # Changes product destination filename. Usefull when one need only change
    # product file name but not it's destination directory. Either new file name
    # or block can be passed. Result of block execution will be used as new name
    # @param newname [String] new file name to be used
    # @yield [oldname] process old file name to generate new name
    # @return [Product] updated product with updated destination filename
    def rename(newname = nil, &_block)
      map do |src, dst, meta|
        filename = File.basename(dst)
        dir = File.dirname(dst)
        dst = newname
        dst = File.join(dir, newname || yield(filename)) unless dir == '.'
        [src, dst, meta]
      end
    end
  end
end
