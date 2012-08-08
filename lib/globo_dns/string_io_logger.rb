module GloboDns

class StringIOLogger < Rails.logger.class
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
