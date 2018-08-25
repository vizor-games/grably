require 'webmock/rspec'
require 'tmpdir'
require 'grably/core'

module Grably
  describe 'Grably#fetch' do
    # Use this file as fixture file name
    let(:filename) { File.basename(__FILE__) }
    # Use this file as downloadable content
    let(:file_content) { IO.binread(__FILE__) }

    let(:default_url) { 'https://example.com/resource' }

    before(:all) { @tmpdir = Dir.mktmpdir }

    context 'When url is passed and resource exists' do
      it do
        stub_request(:get, default_url)
          .to_return(
            status: 200,
            body: file_content,
            headers: { 'Content-Length' => file_content.length,
                       'Content-Disposition' => "attachment; filename=\"#{filename}\"" }
          )

        product = fetch(default_url, @tmpdir, log: false)

        expect(File.basename(product.src)).to eq(filename)
        expect(File.dirname(product.src)).to eq(@tmpdir)
        expect(IO.binread(product.src)).to eq(file_content)
      end
    end

    context 'When filename provided' do
      it do
        stub_request(:get, default_url)
          .to_return(
            status: 200,
            body: file_content,
            headers: { 'Content-Length' => file_content.length,
                       'Content-Disposition' => "attachment; filename=\"#{filename}\"" }
          )

        product = fetch(default_url, @tmpdir, filename: 'a.rb', log: false)

        expect(File.basename(product.src)).to eq('a.rb')
        expect(File.dirname(product.src)).to eq(@tmpdir)
      end
    end

    context 'When http error occured' do
      it do
        stub_request(:get, default_url).to_return(status: 404)

        expect { fetch(default_url, @tmpdir, filename: 'a.rb', log: false) }
          .to raise_error(OpenURI::HTTPError)
      end
    end

    context 'When unknown scheme provided' do
      it do
        expect { fetch('itms://example.com/resource', @tmpdir, log: false) }
          .to raise_error(Errno::ENOENT)
      end
    end

    context 'When timeout reached' do
    end

    after(:all) { FileUtils.rm_rf(@tmpdir) }
  end
end
