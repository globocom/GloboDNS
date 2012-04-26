require 'resolv'

module GloboDns
module Util

    def logger=(value)
        @logger = value
    end

    def logger
        @logger ||= Rails.logger
    end

    # similar to 'Kernel::system', but captures the STDOUT using IO::popen and
    # raises and exception if the return code is not '0' (success)
    def exec(command_id, *args)
        output = nil
        logger.debug "[GloboDns::Util::exec] #{args.join(' ')}"
        IO::popen(args) do |io|
            output = io.read
        end
        $?.exitstatus == 0 or raise "[ERROR] '#{command_id}' failed: #{$?} (#{output})"
        output
    end

    def exec_as_bind(command_id, *args)
        args.unshift(GloboDns::Config::Binaries::SUDO, '-u', GloboDns::Config::BIND_USER)
        exec(command_id, *args)
    end

    def exec_as_root(command_id, *args)
        args.unshift(GloboDns::Config::Binaries::SUDO)
        exec(command_id, *args)
    end

    def resolver
        @@resolver ||= Resolv::DNS::new(:nameserver => GloboDns::Config::NAMESERVER_HOST)
    end

end # Util
end # GloboDns
