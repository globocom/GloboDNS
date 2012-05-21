module SyslogHelper
    def syslog_audit(audit)
        msg  = '[GloboDns]'
        msg << "[#{audit.auditable_type.downcase}:#{audit.action}:#{audit.auditable_id}]"
        msg << "[#{audit.associated_type.downcase}:#{audit.associated_id}]" if audit.associated_type
        msg << "[user:#{audit.user_id}]"                                    if audit.user_id
        msg << "[from:#{audit.remote_address}]"                             if audit.remote_address
        msg << " #{audit.audited_changes.to_json}"
        msg << " (#{audit.comment})"                               if audit.comment

        Rails.syslogger.info msg
    end
end
