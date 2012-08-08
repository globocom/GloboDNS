class Notifier < ActionMailer::Base
    default :from    => "Globo DNS API <dnsapi@globoi.com>",
            :to      => GloboDns::Config::MAIL_RECIPIENTS

    def import_successful(message_body)
        @message_body = message_body
        mail(:subject => I18n.t(:mail_subject_import_successful))
    end

    def import_failed(message_body)
        @message_body = message_body
        mail(:subject => I18n.t(:mail_subject_import_failed))
    end

    def export_successful(message_body)
        @message_body = message_body
        mail(:subject => I18n.t(:mail_subject_export_successful))
    end

    def export_failed(message_body)
        @message_body = message_body
        mail(:subject => I18n.t(:mail_subject_export_failed))
    end
end
