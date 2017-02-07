class FixSrvRecordAttributes < ActiveRecord::Migration
  def change
  	records = Record.where(type: "SRV")
    records.each do |record|
    	if record.prio.nil? or record.weight.nil? or record.port.nil? and !record.content.nil?
    		puts record
	        srv_attr = record.content.split
	        record.prio = srv_attr[0] 
	        record.weight = srv_attr[1] 
	        record.port = srv_attr[2] 
	        record.content = srv_attr[3] 
	        record.save
	    end
    end

  	recordtemplates = RecordTemplate.where(type: "SRV")
    recordtemplates.each do |recordtemplate|
    	if recordtemplate.prio.nil? or recordtemplate.weight.nil? or recordtemplate.port.nil? and !recordtemplate.content.nil?
    	   puts recordtemplate
    	   srv_attr = recordtemplate.content.split
	       recordtemplate.prio = srv_attr[0] 
	       recordtemplate.weight = srv_attr[1] 
	       recordtemplate.port = srv_attr[2] 
	       recordtemplate.content = srv_attr[3] 
	       recordtemplate.save
       end
    end
  end
end
