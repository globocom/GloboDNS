class FixRecordTemplatesAttributes < ActiveRecord::Migration
    def up
        change_table 'record_templates' do |t|
            t.rename 'record_type', 'type'
            t.change 'content', :string, :limit => 4096, :null => false
            t.change 'ttl',     :string,                 :null => true
        end
    end

    def down
        change_table 'record_templates' do |t|
            t.rename 'type', 'record_type'
            t.change 'content', :string, :limit => 255, :null => false
            t.change 'ttl',     :string,                :null => false
        end
    end
end
