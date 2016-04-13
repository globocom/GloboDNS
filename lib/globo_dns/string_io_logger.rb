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

class StringIOLogger < ActiveSupport::TaggedLogging::Formatter
# class StringIOLogger 
#     include ActiveSupport::TaggedLogging

    def initialize(logger)
        super(logger)
        @sio        = StringIO.new('', 'w')
        @sio_logger = Logger.new(@sio)
    end

    def add(severity, message = nil, progname = nil, &block)
        message = (block_given? ? block.call : progname) if message.nil?
        @sio_logger.add(severity, "#{tags_text}#{message}", progname)
        @logger.add(severity, "#{tags_text}#{message}", progname)
    end

    def string
        @sio.string
    end

    def error(*args)
        current_tags << 'ERROR'
        rv = super(*args)
        current_tags.pop
        rv
    end

    def warn(*args)
        current_tags << 'WARNING'
        rv = super(*args)
        current_tags.pop
        rv
    end
end

end
