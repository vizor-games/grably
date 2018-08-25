require 'open-uri'
require 'openssl'

module Grably # :nodoc:
  DEFAULT_FETCH_OPTIONS = {
    read_timeout: 10,
    log: true,
    ssl_verify_mode: ::OpenSSL::SSL::VERIFY_NONE
  }.freeze
  private_constant :DEFAULT_FETCH_OPTIONS

  # File fetch helper.
  # Can be used to download files from provided urls.
  # @param url [String] source file url
  # @param dir [String] directory where file should be placed
  # @param filename [String] optional file name. If filename is provided in HTTP
  #   header it will be replaced. May be nil.
  # @param ssl_verify_mode session verification mode. Valid modes are
  #   VERIFY_NONE, VERIFY_PEER, VERIFY_CLIENT_ONCE, VERIFY_FAIL_IF_NO_PEER_CERT
  #   and defined on OpenSSL::SSL The default mode is VERIFY_NONE, which does
  #   not perform any verification at all.
  # @param read_timeout [Integer] timeout in seconds
  def fetch(url, dir, opts = {})
    content_length = 0
    fetch_params = DEFAULT_FETCH_OPTIONS.merge(opts)
    filename = fetch_params.delete(:filename)
    log = fetch_params.delete(:log)
    fetch_params.update(
      content_length_proc: ->(len) { content_length = len },
      progress_proc: ->(downloaded) { log_progress(downloaded, content_length, log) }
    )

    log_msg "Fetch #{url.white.bright}" if log
    save_stream(open(url, fetch_params), dir, filename, log)
  end

  private

  def save_stream(stream, dir, filename, log)
    # "attachment;filename=\"Stereo Foo - Cohete Amigo.wav\""
    name = (stream.meta['content-disposition'] || '')[/filename=(\"?)(.+)\1/, 2]
    name = filename || name # filename always wins
    log_msg "Saving #{name.white.bright}" if log

    product = Product.new(File.join(dir, name))
    IO.binwrite(product.src, stream.read)
    product
  end

  def log_progress(downloaded, content_length, log)
    return unless content_length > 0 && log

    progress = ((downloaded * 100) / content_length).to_i
    print "Downloading... #{progress.to_s.rjust(3, ' ').white.bright}%\r"
    puts "\n" if progress == 100
  end
end
