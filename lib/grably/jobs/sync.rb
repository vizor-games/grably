module Grably # :nodoc:
  # TBD
  class SyncJob
    include Grably::Job

    PROTO_SSH = %r{^ssh://(.*)$}
    SSH_HOST = /(.+?):(.+?)@(.+)/
    DEFAULT_RSYNC_PARAMS = %w(-avz --progress --delete).freeze

    srcs :files
    opt :dst

    opt :host
    opt :proto
    opt :no_partial
    opt :ssh_key
    opt :ssh_pass
    opt :ssh_port

    def setup(srcs, dst = nil, _p = {})
      @files = srcs
      @dst = dst || job_dir

      @proto = :file

      unpack_dst_hash(@dst) unless @dst.is_a?(String)
      @dst.match(PROTO_SSH) do |m|
        @proto = :ssh
        @dst = m[1]
      end
      setup_ssh_opts if @proto == :ssh
    end

    def changed?
      true
    end

    def build
      trace "Syncing products to #{dst}"
      cp_smart(files, dst, log: proto == :file)
      ssh_sync if proto == :ssh
      proto == :ssh ? [] : dst
    end

    private

    def ssh_cmd
      cmd = %w(ssh)
      cmd += ['-i', ssh_key] if ssh_key
      cmd += ['-p', ssh_port] if ssh_port
      cmd =  ['sshpass', '-p', ssh_pass] + cmd if ssh_pass
      "'#{cmd.join(' ')}'"
    end

    def unpack_dst_hash(dst)
      @proto = :ssh
      @no_partial = dst[:no_partial]
      @ssh_key = dst[:ssh_key]
      @ssh_pass = dst[:ssh_pass]
      @ssh_port = dst[:ssh_port]
      @dst = dst[:host]
    end

    def ssh_sync
      if files.empty?
        warn 'Nothing to sync' if files.empty?
      end

      log "Syncing #{files.size} files to #{host}"
      ['rsync', *rsync_params, @dst, '-e', ssh_cmd, host].run_log
    end

    def rsync_params
      params = DEFAULT_RSYNC_PARAMS.dup
      params << '--partial' unless no_partial

      params
    end

    def setup_ssh_opts
      @host = @dst
      @dst = job_dir('files') + '/' # This will cause to sync internal file structure

      @host.match(SSH_HOST) do |m|
        @ssh_pass = m[2]
        @host = [m[1], m[2]].join('@')
      end
    end
  end
end
