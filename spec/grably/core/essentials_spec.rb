require 'grably/core/essentials'

module Grably
  module Essentials
    describe 'Essentials::detect_host_os' do
      context 'when host_os is linux' do
        it { expect(Essentials.detect_host_os('linux-gnu')).to be(:linux) }
      end

      context 'when host_os is mac' do
        it { expect(Essentials.detect_host_os('darwin17.3.0')).to be(:mac) }
      end
    end
  end
end
