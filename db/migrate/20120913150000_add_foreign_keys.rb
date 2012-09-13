class AddForeignKeys < ActiveRecord::Migration
    def up
      execute "ALTER TABLE `audits` ADD 
        CONSTRAINT `fk_audits_users1`
          FOREIGN KEY (`user_id` )
          REFERENCES `users` (`id` )
          ON DELETE NO ACTION
          ON UPDATE NO ACTION"
          
      execute "CREATE INDEX `fk_audits_users1` ON `audits` (`user_id` ASC)"
      
      execute "ALTER TABLE `domain_templates` ADD 
       CONSTRAINT `fk_domain_templates_views1`
          FOREIGN KEY (`view_id` )
          REFERENCES `views` (`id` )
          ON DELETE NO ACTION
          ON UPDATE NO ACTION"
          
      execute "CREATE INDEX `fk_domain_templates_views2` ON `domain_templates` (`view_id` ASC)"
      
      execute "ALTER TABLE `domains` ADD 
        CONSTRAINT `fk_domains_users`
          FOREIGN KEY (`user_id` )
          REFERENCES `users` (`id` )
          ON DELETE NO ACTION
          ON UPDATE NO ACTION"
          
      execute "ALTER TABLE `domains` ADD 
            CONSTRAINT `fk_domains_views1`
              FOREIGN KEY (`view_id` )
              REFERENCES `views` (`id` )
              ON DELETE NO ACTION
              ON UPDATE NO ACTION"
              
      execute "CREATE INDEX `fk_domains_users2` ON `domains` (`user_id` ASC)"
      
      execute "CREATE INDEX `fk_domains_views2` ON `domains` (`view_id` ASC)"
      
      execute "ALTER TABLE `record_templates` ADD 
        CONSTRAINT `fk_record_templates_domain_templates1`
          FOREIGN KEY (`domain_template_id` )
          REFERENCES `domain_templates` (`id` )
          ON DELETE NO ACTION
          ON UPDATE NO ACTION"
          
      execute "CREATE INDEX `fk_record_templates_domain_templates2` ON `record_templates` (`domain_template_id` ASC)"
      
      execute "ALTER TABLE `records` ADD 
        CONSTRAINT `fk_records_domains1`
          FOREIGN KEY (`domain_id` )
          REFERENCES `domains` (`id` )
          ON DELETE NO ACTION
          ON UPDATE NO ACTION"
          
      execute "CREATE INDEX `fk_records_domains2` ON `records` (`domain_id` ASC)"
      
    end
    
    def down
      raise ActiveRecord::IrreversibleMigration
    end
end
