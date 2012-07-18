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
        self.logger.info  "[GloboDns::Util::exec] #{args.join(' ')}"
        Rails.logger.info "[GloboDns::Util::exec] #{args.join(' ')}"
        puts              "[GloboDns::Util::exec] #{args.join(' ')}"
        IO::popen(args) do |io|
            output = io.read
        end
        $?.exitstatus == 0 or raise ExitStatusError.new("[ERROR] '#{command_id}' failed: #{$?} (#{output})")
        output
    end

    # same as 'exec', but don't raise an exception if the exit status is not 0
    def self.exec!(command_id, *args)
        output = nil
        self.logger.info "[GloboDns::Util::exec!] #{args.join(' ')}"
        puts "[GloboDns::Util::exec!] #{args.join(' ')}"
        IO::popen(args) do |io|
            output = io.read
        end
        puts "$?: #{$?}"
        puts "$?.exitstatus: #{$?.exitstatus}"
        output
    rescue Exception => e
        "#{output}\n#{e}\n#{e.backtrace}"
    end

    def self.exec_as_bind(command_id, *args)
        args.unshift(GloboDns::Config::Binaries::SUDO, '-u', GloboDns::Config::BIND_USER)
        exec(command_id, *args)
    end

    def self.exec_as_root(command_id, *args)
        args.unshift(GloboDns::Config::Binaries::SUDO)
        exec(command_id, *args)
    end

    def self.last_export_timestamp
        @last_commit_date = Time.at(exec('git last commit date', GloboDns::Config::Binaries::GIT, 'log', '-1', '--format=%at').to_i)
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

        def last_export_timestamp
            GloboDns::Util::last_export_timestamp
        end
    end

end # Util
end # GloboDns
