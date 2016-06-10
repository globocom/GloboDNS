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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160613182510) do

  create_table "audits", force: :cascade do |t|
    t.integer  "auditable_id",    limit: 4
    t.string   "auditable_type",  limit: 255
    t.integer  "associated_id",   limit: 4
    t.string   "associated_type", limit: 255
    t.integer  "user_id",         limit: 4
    t.string   "user_type",       limit: 255
    t.string   "username",        limit: 255
    t.string   "action",          limit: 255
    t.text     "audited_changes", limit: 65535
    t.integer  "version",         limit: 4,     default: 0
    t.string   "comment",         limit: 255
    t.string   "remote_address",  limit: 255
    t.datetime "created_at"
    t.string   "request_uuid",    limit: 255
  end

  add_index "audits", ["associated_id", "associated_type"], name: "associated_index", using: :btree
  add_index "audits", ["auditable_id", "auditable_type"], name: "auditable_index", using: :btree
  add_index "audits", ["created_at"], name: "index_audits_on_created_at", using: :btree
  add_index "audits", ["request_uuid"], name: "index_audits_on_request_uuid", using: :btree
  add_index "audits", ["user_id", "user_type"], name: "user_index", using: :btree
  add_index "audits", ["user_id"], name: "fk_audits_users1", using: :btree

  create_table "domain_templates", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "ttl",        limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "view_id",    limit: 4
  end

  add_index "domain_templates", ["view_id"], name: "fk_domain_templates_views2", using: :btree

  create_table "domains", force: :cascade do |t|
    t.integer  "user_id",         limit: 4
    t.string   "name",            limit: 255
    t.string   "master",          limit: 255
    t.integer  "last_check",      limit: 4
    t.integer  "notified_serial", limit: 4
    t.string   "account",         limit: 255
    t.string   "ttl",             limit: 255
    t.text     "notes",           limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "authority_type",  limit: 1,     null: false
    t.string   "addressing_type", limit: 1,     null: false
    t.integer  "view_id",         limit: 4
    t.integer  "sibling_id",      limit: 4
  end

  add_index "domains", ["name"], name: "index_domains_on_name", using: :btree
  add_index "domains", ["user_id"], name: "fk_domains_users2", using: :btree
  add_index "domains", ["view_id"], name: "fk_domains_views2", using: :btree

  create_table "record_templates", force: :cascade do |t|
    t.integer  "domain_template_id", limit: 4
    t.string   "name",               limit: 255
    t.string   "type",               limit: 255,  null: false
    t.string   "content",            limit: 4096, null: false
    t.string   "ttl",                limit: 255
    t.integer  "prio",               limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "record_templates", ["domain_template_id"], name: "fk_record_templates_domain_templates2", using: :btree

  create_table "records", force: :cascade do |t|
    t.integer  "domain_id",  limit: 4,    null: false
    t.string   "name",       limit: 255,  null: false
    t.string   "type",       limit: 255,  null: false
    t.string   "content",    limit: 4096, null: false
    t.string   "ttl",        limit: 255
    t.integer  "prio",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "records", ["domain_id"], name: "fk_records_domains2", using: :btree
  add_index "records", ["domain_id"], name: "index_records_on_domain_id", using: :btree
  add_index "records", ["name", "type"], name: "index_records_on_name_and_type", using: :btree
  add_index "records", ["name"], name: "index_records_on_name", using: :btree

  create_table "schedules", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.datetime "date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "schedules", ["name"], name: "index_schedules_on_name", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "login",                limit: 255
    t.string   "email",                limit: 255
    t.string   "encrypted_password",   limit: 255
    t.string   "password_salt",        limit: 255
    t.string   "role",                 limit: 1
    t.string   "authentication_token", limit: 255
    t.datetime "remember_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",                           default: true
    t.string   "name",                 limit: 255
    t.string   "oauth_token",          limit: 255
    t.datetime "oauth_expires_at"
    t.string   "uid",                  limit: 255
    t.string   "password",             limit: 255, default: "password"
    t.string   "provider",             limit: 255
  end

  create_table "views", force: :cascade do |t|
    t.string   "name",         limit: 32,   null: false
    t.string   "clients",      limit: 1024
    t.string   "destinations", limit: 1024
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "key",          limit: 64
  end

  add_foreign_key "audits", "users", name: "fk_audits_users1"
  add_foreign_key "domain_templates", "views", name: "fk_domain_templates_views1"
  add_foreign_key "domains", "users", name: "fk_domains_users"
  add_foreign_key "domains", "views", name: "fk_domains_views1"
  add_foreign_key "record_templates", "domain_templates", name: "fk_record_templates_domain_templates1"
  add_foreign_key "records", "domains", name: "fk_records_domains1"
end
