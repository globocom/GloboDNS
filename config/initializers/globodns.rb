require 'globo_dns/config'

GloboDns::Config::load_from_file(Rails.root.join('config', 'globodns.yml'))
