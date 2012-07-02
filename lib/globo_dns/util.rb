module GloboDns
module Util

    class ExitStatusError < ::RuntimeError; end

    def self.logger=(value)
        @@logger = value
    end

    def self.logger
        @@logger ||= Rails.logger
    end

    # similar to 'Kernel::system', but captures the STDOUT using IO::popen and
    # raises and exception if the return code is not '0' (success)
    def self.exec(command_id, *args)
        output = nil
        self.logger.debug "[GloboDns::Util::exec] #{args.join(' ')}"
        self.logger.puts  "[GloboDns::Util::exec] #{args.join(' ')}"
        IO::popen(args) do |io|
            output = io.read
        end
        $?.exitstatus == 0 or raise ExitStatusError.new("[ERROR] '#{command_id}' failed: #{$?} (#{output})")
        output
    end

    # same as 'exec', but don't raise an exception if the exit status is not 0
    def self.exec!(command_id, *args)
        output = nil
        self.logger.debug "[GloboDns::Util::exec!] #{args.join(' ')}"
        IO::popen(args) do |io|
            output = io.read
        end
        output
    end

    def self.exec_as_bind(command_id, *args)
        args.unshift(GloboDns::Config::Binaries::SUDO, '-u', GloboDns::Config::BIND_USER)
        exec(command_id, *args)
    end

    def self.exec_as_root(command_id, *args)
        args.unshift(GloboDns::Config::Binaries::SUDO)
        exec(command_id, *args)
    end

    def self.included(base)
        base.send(:include, InstanceMethods)
    end

    module InstanceMethods
        def exec(command_id, *args)
            GloboDns::Util::exec(command_id, *args)
        end

        def exec!(command_id, *args)
            GloboDns::Util::exec!(command_id, *args)
        end

        def exec_as_bind(command_id, *args)
            GloboDns::Util::exec_as_bind(command_id, *args)
        end

        def exec_as_root(command_id, *args)
            GloboDns::Util::exec_as_root(command_id, *args)
        end
    end

end # Util
end # GloboDns
