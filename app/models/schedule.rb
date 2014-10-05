class Schedule < ActiveRecord::Base
    attr_accessible :name, :date

    def self.get name
        Schedule.where(:name => name).first_or_create
    end

    def self.run_exclusive name
        s = Schedule.where(:name => name).first_or_create
        s.with_lock do
            ret = yield s
            s.save
            return ret
        end
    end

end
