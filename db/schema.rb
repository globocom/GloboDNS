# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120913150000) do

  create_table "audits", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "associated_id"
    t.string   "associated_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "username"
    t.string   "action"
    t.text     "audited_changes"
    t.integer  "version",         :default => 0
    t.string   "comment"
    t.string   "remote_address"
    t.datetime "created_at"
  end

  add_index "audits", ["associated_id", "associated_type"], :name => "associated_index"
  add_index "audits", ["auditable_id", "auditable_type"], :name => "auditable_index"
  add_index "audits", ["created_at"], :name => "index_audits_on_created_at"
  add_index "audits", ["user_id", "user_type"], :name => "user_index"
  add_index "audits", ["user_id"], :name => "fk_audits_users1"

  create_table "domain_templates", :force => true do |t|
    t.string   "name"
    t.string   "ttl",        :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "view_id"
  end

  add_index "domain_templates", ["view_id"], :name => "fk_domain_templates_views2"

  create_table "domains", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "master"
    t.integer  "last_check"
    t.integer  "notified_serial"
    t.string   "account"
    t.string   "ttl"
    t.text     "notes"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.string   "authority_type",  :limit => 1, :null => false
    t.string   "addressing_type", :limit => 1, :null => false
    t.integer  "view_id"
  end

  add_index "domains", ["name"], :name => "index_domains_on_name"
  add_index "domains", ["user_id"], :name => "fk_domains_users2"
  add_index "domains", ["view_id"], :name => "fk_domains_views2"

  create_table "record_templates", :force => true do |t|
    t.integer  "domain_template_id"
    t.string   "name"
    t.string   "record_type",        :null => false
    t.string   "content",            :null => false
    t.string   "ttl",                :null => false
    t.integer  "prio"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  add_index "record_templates", ["domain_template_id"], :name => "fk_record_templates_domain_templates2"

  create_table "records", :force => true do |t|
    t.integer  "domain_id",                  :null => false
    t.string   "name",                       :null => false
    t.string   "type",                       :null => false
    t.string   "content",    :limit => 4096, :null => false
    t.string   "ttl"
    t.integer  "prio"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  add_index "records", ["domain_id"], :name => "fk_records_domains2"
  add_index "records", ["domain_id"], :name => "index_records_on_domain_id"
  add_index "records", ["name", "type"], :name => "index_records_on_name_and_type"
  add_index "records", ["name"], :name => "index_records_on_name"

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "encrypted_password",   :limit => 128, :null => false
    t.string   "password_salt",        :limit => 128, :null => false
    t.string   "role",                 :limit => 1
    t.string   "authentication_token"
    t.datetime "remember_created_at"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
  end

  create_table "views", :force => true do |t|
    t.string   "name",         :limit => 32,   :null => false
    t.string   "clients",      :limit => 1024
    t.string   "destinations", :limit => 1024
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.string   "key",          :limit => 64
  end

end
