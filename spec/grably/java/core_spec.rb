require 'ostruct'

require 'grably/core/essentials'
require 'grably/java/core'

module Grably
  module Java
    describe '#detect_jdk' do
      context 'when ENV already populated' do
        it do
          allow(ENV).to receive(:[]).with(JDK_ENV_KEY) { '/sample/home/java' }
          allow(ENV).to receive(:[]).with(JAVA_TARGET_ENV_KEY) { '9' }
          allow(ENV).to receive(:[]).with('java_target') { nil }
          allow(ENV).to receive(:[]).with('java_source') { nil }
          allow(Java).to receive(:c) { OpenStruct.new }

          expect(Java.detect_jdk).to match_array(%w(/sample/home/java 9 9))
        end
      end

      context 'when ENV is empty' do
        it do
          allow(ENV).to receive(:[]).with(JDK_ENV_KEY) { nil }
          allow(ENV).to receive(:[]).with(JAVA_TARGET_ENV_KEY) { nil }
          allow(ENV).to receive(:[]).with('java_target') { nil }
          allow(ENV).to receive(:[]).with('java_source') { nil }

          allow(Java).to receive(:c) { OpenStruct.new }
          allow(Java).to receive(:which_java) { %w(/sample/home/java 9) }

          expect(Java.detect_jdk).to match_array(%w(/sample/home/java 9 9))
        end
      end

      context 'when env overwrites java target' do
        it do
          allow(ENV).to receive(:[]).with(JDK_ENV_KEY) { '/sample/home/java' }
          allow(ENV).to receive(:[]).with(JAVA_TARGET_ENV_KEY) { '9' }
          allow(ENV).to receive(:[]).with('java_target') { '10' }
          allow(ENV).to receive(:[]).with('java_source') { nil }
          allow(Java).to receive(:c) { OpenStruct.new }

          expect(Java.detect_jdk).to match_array(%w(/sample/home/java 10 10))
        end
      end

      context 'when env overwrites java source' do
        it do
          allow(ENV).to receive(:[]).with(JDK_ENV_KEY) { '/sample/home/java' }
          allow(ENV).to receive(:[]).with(JAVA_TARGET_ENV_KEY) { '9' }
          allow(ENV).to receive(:[]).with('java_target') { nil }
          allow(ENV).to receive(:[]).with('java_source') { '10' }
          allow(Java).to receive(:c) { OpenStruct.new }

          expect(Java.detect_jdk).to match_array(%w(/sample/home/java 9 10))
        end
      end

      context 'when env overwrites java target and java source' do
        it do
          allow(ENV).to receive(:[]).with(JDK_ENV_KEY) { '/sample/home/java' }
          allow(ENV).to receive(:[]).with(JAVA_TARGET_ENV_KEY) { '9' }
          allow(ENV).to receive(:[]).with('java_target') { '11' }
          allow(ENV).to receive(:[]).with('java_source') { '10' }
          allow(Java).to receive(:c) { OpenStruct.new }

          expect(Java.detect_jdk).to match_array(%w(/sample/home/java 11 10))
        end
      end

      context 'when config overwrites java target' do
        it do
          allow(ENV).to receive(:[]).with(JDK_ENV_KEY) { '/sample/home/java' }
          allow(ENV).to receive(:[]).with(JAVA_TARGET_ENV_KEY) { '9' }
          allow(ENV).to receive(:[]).with('java_target') { nil }
          allow(ENV).to receive(:[]).with('java_source') { nil }
          allow(Java).to receive(:c) { OpenStruct.new(java_target: '10') }

          expect(Java.detect_jdk).to match_array(%w(/sample/home/java 10 10))
        end
      end

      context 'when config overwrites java source' do
        it do
          allow(ENV).to receive(:[]).with(JDK_ENV_KEY) { '/sample/home/java' }
          allow(ENV).to receive(:[]).with(JAVA_TARGET_ENV_KEY) { '9' }
          allow(ENV).to receive(:[]).with('java_target') { nil }
          allow(ENV).to receive(:[]).with('java_source') { nil }
          allow(Java).to receive(:c) { OpenStruct.new(java_source: '10') }

          expect(Java.detect_jdk).to match_array(%w(/sample/home/java 9 10))
        end
      end

      context 'when config overwrites java source' do
        it do
          allow(ENV).to receive(:[]).with(JDK_ENV_KEY) { '/sample/home/java' }
          allow(ENV).to receive(:[]).with(JAVA_TARGET_ENV_KEY) { '9' }
          allow(ENV).to receive(:[]).with('java_target') { nil }
          allow(ENV).to receive(:[]).with('java_source') { nil }
          allow(Java).to receive(:c) { OpenStruct.new(java_source: '10', java_target: '11') }

          expect(Java.detect_jdk).to match_array(%w(/sample/home/java 11 10))
        end
      end
    end

    describe '#which_java' do
      it 'Returns jdk home and java specification version' do
        skip('No JAVA_HOME or JAVA_SPEC_VERSION provided from ENV') unless ENV['JAVA_HOME'] && ENV['JAVA_SPEC_VERSION']
        expect(Java.which_java).to match_array([ENV['JAVA_HOME'], ENV['JAVA_SPEC_VERSION']])
      end
    end
  end
end
