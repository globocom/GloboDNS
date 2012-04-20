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

ActiveRecord::Schema.define(:version => 20120420202106) do

  create_table "audits", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "associated_id"
    t.string   "associated_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "username"
    t.string   "remote_address"
    t.string   "action"
    t.text     "audited_changes"
    t.string   "comment"
    t.integer  "version",         :default => 0
    t.datetime "created_at"
  end

  add_index "audits", ["associated_id", "associated_type"], :name => "associated_index"
  add_index "audits", ["auditable_id", "auditable_type"], :name => "auditable_index"
  add_index "audits", ["created_at"], :name => "index_audits_on_created_at"
  add_index "audits", ["user_id", "user_type"], :name => "user_index"

  create_table "domain_templates", :force => true do |t|
    t.string   "name"
    t.integer  "ttl",        :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "domains", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "master"
    t.integer  "last_check"
    t.integer  "notified_serial"
    t.string   "account"
    t.integer  "ttl"
    t.text     "notes"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.string   "authority_type",  :limit => 1, :null => false
    t.string   "addressing_type", :limit => 1, :null => false
  end

  add_index "domains", ["name"], :name => "index_domains_on_name"

  create_table "record_templates", :force => true do |t|
    t.integer  "domain_template_id"
    t.string   "name"
    t.string   "record_type",        :null => false
    t.string   "content",            :null => false
    t.integer  "ttl",                :null => false
    t.integer  "prio"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "records", :force => true do |t|
    t.integer  "domain_id",  :null => false
    t.string   "name",       :null => false
    t.string   "type",       :null => false
    t.string   "content",    :null => false
    t.integer  "ttl"
    t.integer  "prio"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "records", ["domain_id"], :name => "index_records_on_domain_id"
  add_index "records", ["name", "type"], :name => "index_records_on_name_and_type"
  add_index "records", ["name"], :name => "index_records_on_name"

  create_table "supermasters", :id => false, :force => true do |t|
    t.string "ip",         :limit => 25, :null => false
    t.string "nameserver",               :null => false
    t.string "account",    :limit => 40
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "encrypted_password",   :limit => 128,  :null => false
    t.string   "password_salt",        :limit => 128,  :null => false
    t.string   "role",                 :limit => 1
    t.datetime "remember_created_at"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.string   "authentication_token", :limit => 1024
  end

end
