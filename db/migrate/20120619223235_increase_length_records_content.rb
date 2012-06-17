class IncreaseLengthRecordsContent < ActiveRecord::Migration
    def up
        change_table 'records' do |t|
            t.change :content, :string, :null => false, :limit => 4096
        end
    end

    def down
        change_table 'records' do |t|
            t.change :content, :string, :null => false
        end
    end
end
