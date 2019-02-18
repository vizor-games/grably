require 'grably/java/maven'

RSpec::Matchers.define :match_directory_manifest do |manifest|
  match do |dir|
    @actual = describe_dir(dir)
    (@actual - manifest).empty? && (manifest - @actual).empty?
  end

  failure_message do |_actual|
    extra_files = (@actual - manifest).sort_by { |f| f['file'] }.map do |f|
      "\t- #{f['file']} (#{f['sha1']})"
    end
    missing_files = (manifest - @actual).sort_by { |f| f['file'] }.map do |f|
      "\t- #{f['file']} (#{f['sha1']})"
    end

    ['Extra files:', extra_files, 'Missing files:', missing_files].join("\n")
  end
end

module Grably
  module Maven
    describe Resolver do
      # Read all yamls from maven dir and generate test cases. We basicaly check
      # that resolver bechaves same way as maven command
      fixtures = Dir[File.join(__dir__, 'maven/maven_*.yml')]
                 .map { |f| YAML.safe_load(IO.read(f)) }
      fixtures.each do |fixture|
        context fixture['desc'] do
          before { @dir = Dir.mktmpdir }

          it do
            repos = fixture['repos'] || [:central]
            resolver = Maven::Resolver.new(repos: repos,
                                           sources: fixture['sources'],
                                           javadoc: fixture['javadoc'])

            fixture['targets'].each do |t|
              resolver.add_lib(Resolver.parse_lib(t))
            end

            WebMock.disable!
            resolver.resolve
            if ENV['MAVEN_DUMP']
              dump_file = "deps-#{fixture['desc'].downcase.tr(' ', '-')}-#{Time.now.to_i}.yml"
              resolver.dump(File.join('/tmp/', dump_file))
            end
            resolver.fetch(@dir)
            WebMock.enable!

            expect(@dir).to match_directory_manifest(fixture['sums'])
          end

          after { FileUtils.rm_rf(@dir) }
        end
      end

      context 'when created resolver with missing alias' do
        it do
          expect { Resolver.new(repos: %i(blabla)) }
            .to raise_error(RuntimeError, 'Unknown repository alias: blabla')
        end
      end
    end
  end
end
