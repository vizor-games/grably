module Grably
  class ManifestJob # :nodoc:
    include Grably::Job

    PRIMARY_KEYS = [
      /Manifest-Version/,
      /Midlet-Name/,
      /MIDlet-Version/,
      /MIDlet-Vendor/,
      /MIDlet-Jar-URL/,
      /MIDlet-Jar-Size/,
      /MIDlet-Description/,
      /MIDlet-Icon/,
      /MIDlet-Info-URL/,
      /MIDlet-[0-9]*/,
      /MIDlet-Delete-Confirm/,
      /MIDlet-Permissions/,
      /MicroEdition-Configuration/,
      /MicroEdition-Profile/
    ].freeze

    MANIFEST_LINE_SIZE = 70

    opt :params

    def setup(p)
      raise "params should be a Hash: #{p.inspect}" unless p.is_a? Hash

      @params = p
    end

    def file_name
      'META-INF/MANIFEST.MF'
    end

    def write_line(f, s)
      while s.size > MANIFEST_LINE_SIZE
        f.puts(s[0..MANIFEST_LINE_SIZE - 1])
        s = ' ' + s[MANIFEST_LINE_SIZE..-1]
      end
      f.puts(s)
    end

    def forced_params
      {}
    end

    def splitter
      # by default use default line splitter
      nil
    end

    def build
      opts = forced_params.merge(@params)

      mf = job_path('MANIFEST.MF')
      File.open(mf, 'w') do |f|
        f.puts(self.class.create_manifest(opts, splitter))
      end

      Product.new(mf, file_name)
    end

    def self.rate(s)
      PRIMARY_KEYS.each do |k|
        return PRIMARY_KEYS.index(k) if k =~ s
      end

      PRIMARY_KEYS.size
    end

    def self.create_manifest(opts, splitter) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      if splitter.nil?
        splitter = lambda do |s|
          lines = []
          while s.size > MANIFEST_LINE_SIZE
            lines << s[0..MANIFEST_LINE_SIZE - 1]
            s = ' ' + s[MANIFEST_LINE_SIZE..-1]
          end
          lines << s
          lines
        end
      end

      keys = opts.keys.sort do |x, y|
        rx = rate(x)
        ry = rate(y)
        if rx == ry
          x <=> y
        else
          rx <=> ry
        end
      end

      lines = []

      keys.each do |k|
        v = opts[k]
        v *= ',' if v.is_a? Array
        s = "#{k}: #{v}"
        l = splitter.call(s)
        l = [l] unless l.is_a? Array
        lines += l
      end

      lines.join("\n")
    end
  end
end
