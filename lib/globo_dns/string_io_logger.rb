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

# class StringIOLogger < ActiveSupport::TaggedLogging
class StringIOLogger 

    def initialize(logger)
        @logger = ActiveSupport::TaggedLogging.new(logger)
        @sio        = StringIO.new('', 'w')
        @sio_logger = Logger.new(@sio)
        @console_logger = Logger.new(STDOUT)
    end

    def add(severity, message = nil, progname = nil, &block)
        message = (block_given? ? block.call : progname) if message.nil?
        @sio_logger.add(severity, "#{message}", progname)
        @logger.add(severity, "#{message}", progname)
    end

    def string
        @sio.string
    end

    def error(*args)
        rv = @logger.error(*args)
        add(Logger::Severity::ERROR,*args,'globodns')
        rv
    end

    def warn(*args)
        rv = @logger.warn(*args)
        add(Logger::Severity::WARN,*args,'globodns')
        rv
    end

    def info(*args)
        rv = @logger.info(*args)
        add(Logger::Severity::INFO,*args,'globodns')
        rv
    end

    def debug(*args)
        rv = @logger.debug(*args)
        add(Logger::Severity::DEBUG,*args,'globodns')
        rv
    end
end

end