module Grably
  # Creates single fat or uber jar of provided jar files. Main steps to produce
  # fat jar are:
  #  - unpack every provided jar to temporary directory
  #  - drop all *.{SF,DSA,RSA} files from META-INF directory because repacing
  #    breaks signing
  #  - add manifest
  #  - pack everything into single jar file
  class FatJar
    include Grably::Job
    include FileUtils

    srcs :jars
    src :manifest
    opt :name

    # FatJar job setup method
    # @param jars [Array<Product>]  list of jar files to process. May be
    #   expandable expression
    # @param manifest [Product] file with jar manifest
    # @param name [String] name of resulting jar file
    def setup(jars, manifest, name: 'a.jar')
      @jars = jars
      @manifest = manifest
      @name = name
    end

    def build
      out = job_path(name)
      Product.expand([prepare, manifest], out)
      out
    end

    private

    def prepare
      tmp = job_path('tmp')
      jars.select(&:jar?).each do |jar|
        unpack(jar, File.join(tmp, File.basename(jar, '*.jar')))
      end

      # Remove all sigantures
      rm(Dir[File.join(tmp, '**/*.{SF,DSA,RSA}')])

      # Collect all files
      Product.expand(Dir[File.join(tmp, '*')].map { |x| { x => '**/*' } })
    end
  end
end
