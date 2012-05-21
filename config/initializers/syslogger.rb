Rails.class_eval do
    def self.syslogger
        @logger ||= Syslogger.new('globodns', Syslog::LOG_PID | Syslog::LOG_CONS, Syslog::LOG_LOCAL0)
    end
end
