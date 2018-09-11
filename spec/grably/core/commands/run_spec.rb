require 'grably/core/commands'
require 'grably/core/essentials'

module Grably
  module Commands
    describe '#run' do
      include Grably::Commands

      let(:pwd) do
        if windows?
          %w(echo %cd%)
        else
          %w(pwd)
        end
      end

      context 'when command completes' do
        it { expect(pwd.run).to eq(Dir.pwd) }
      end

      context 'when command executed with chdir argument' do
        it { expect(pwd.run(chdir: __dir__)).to eq(__dir__) }
      end

      context 'when command returns multiline output' do
        it { expect(%W(echo a\nb\nc).run).to eq("a\nb\nc") }
      end

      context 'when command execution fails' do
        let(:cmd) { [RbConfig.ruby, '-e', 'raise "Failed!"'] }
        it { expect { cmd.run }.to raise_error(RuntimeError, /error:/) }
        it { expect { cmd.run }.to raise_error(RuntimeError, /Failed/) }
        it do
          expect { cmd.run }.to raise_error(RuntimeError)
          expect(Grably.last_command)
            .to start_with(cmd, 1, a_string_matching(/Failed!/))
        end
      end
    end
  end
end
