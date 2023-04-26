namespace :record do
  desc "Increase ttl of records updated three days ago until it reach its domain ttl"
  task increase_ttl: :environment do

    include GloboDns::Config

    records = Record.to_update_ttl
    Rails.logger.info "[Record] Increasing TTL of #{records.count} records"
    records.each do |record|
      Rails.logger.info "[Record] Updating ttl of record #{record.name} of #{record.domain.name}"
      record.increase_ttl
    end
    if records.count > 0
      schedule_date = Schedule.run_exclusive :schedule do |s|
        s.date ||= Time.at(((DateTime.now + GloboDns::Config::EXPORT_DELAY.seconds).to_i / 60.0 + 1).round * 60)
      end
    end

    Rails.logger.info "[Record] Done increasing TTL"
  end
end
