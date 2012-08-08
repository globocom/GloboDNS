module SyslogHelper
    def syslog_audit(audit)
        msg  = "[#{audit.auditable_type.downcase}:#{audit.action}:#{audit.auditable_id}]"
        msg << "[#{audit.associated_type.downcase}:#{audit.associated_id}]" if audit.associated_type
        msg << "[user:#{audit.user.login}]"                                 if audit.user && audit.user.login
        msg << "[from:#{audit.remote_address}]"                             if audit.remote_address
        msg << " #{audit.audited_changes.to_json}"
        msg << " (#{audit.comment})"                                        if audit.comment

        Rails.syslogger.info msg
    end

    def syslog_info(message)
        Rails.syslogger.info "[INFO] #{message}"
    end

    def syslog_error(message)
        Rails.syslogger.error "[ERROR] #{message}"
    end
end
