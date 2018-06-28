namespace :record do
  desc "Increase ttl of records updated three days ago until it reach its domain ttl"
  task increase_ttl: :environment do
    records = Record.to_update_ttl
    Rails.logger.info "[Record] Increasing TTL of #{records.count} records"
    records.each do |record|
      Rails.logger.info "[Record] Updating ttl of record #{record.name} of #{record.domain.name}"
      record.increase_ttl
    end
    Rails.logger.info "[Record] Done increasing TTL"
  end
end
