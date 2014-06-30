# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
        self.logger.info "[GloboDns::Util::exec] #{args.join(' ')}"
        IO::popen(args + [:err => [:child, :out]]) do |io|
            output = io.read
        end
        $?.exitstatus == 0 or raise ExitStatusError.new("[ERROR] '#{command_id}' failed: #{$?} (#{output})")
        output
    end

    # same as 'exec', but don't raise an exception if the exit status is not 0
    def self.exec!(command_id, *args)
        output = nil
        self.logger.info "[GloboDns::Util::exec!] #{args.join(' ')}"
        IO::popen(args + [:err => [:child, :out]]) do |io|
            output = io.read
        end
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
        Dir.chdir(File.join(GloboDns::Config::EXPORT_MASTER_CHROOT_DIR, GloboDns::Config::BIND_MASTER_ZONES_DIR)) do
            Time.at(exec('git last commit date', GloboDns::Config::Binaries::GIT, 'log', '-1', '--format=%at').to_i)
        end
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
