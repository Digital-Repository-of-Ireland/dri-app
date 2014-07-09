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

ActiveRecord::Schema.define(version: 20140708132006) do

  create_table "bookmarks", force: true do |t|
    t.integer  "user_id",       null: false
    t.string   "document_id"
    t.string   "title"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "user_type"
    t.string   "document_type"
  end

  add_index "bookmarks", ["user_id"], name: "index_bookmarks_on_user_id"

  create_table "institutes", force: true do |t|
    t.string   "name"
    t.string   "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "logo"
  end

  add_index "institutes", ["name"], name: "index_institutes_on_name"

  create_table "licences", force: true do |t|
    t.string   "name"
    t.string   "url"
    t.string   "logo"
    t.string   "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "local_files", force: true do |t|
    t.string  "path"
    t.string  "fedora_id"
    t.string  "ds_id"
    t.string  "mime_type"
    t.integer "version"
    t.text    "checksum"
  end

  create_table "searches", force: true do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "user_type"
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id"

  create_table "user_group_authentications", force: true do |t|
    t.integer "user_id"
    t.string  "provider"
    t.string  "uid"
  end

  create_table "user_group_groups", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.boolean  "is_locked",   default: false
  end

  add_index "user_group_groups", ["name"], name: "index_groups_on_name", unique: true

  create_table "user_group_memberships", force: true do |t|
    t.integer  "group_id"
    t.integer  "user_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "approved_by"
  end

  add_index "user_group_memberships", ["group_id", "user_id"], name: "index_memberships_on_group_id_and_user_id", unique: true

  create_table "user_group_users", force: true do |t|
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "authentication_token"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.string   "first_name"
    t.string   "second_name"
    t.string   "locale"
    t.boolean  "guest",                  default: false
    t.integer  "view_level",             default: 0
    t.string   "about_me",               default: ""
    t.datetime "token_creation_date"
    t.string   "image_link"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
  end

  add_index "user_group_users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true
  add_index "user_group_users", ["confirmation_token"], name: "index_user_group_users_on_confirmation_token", unique: true
  add_index "user_group_users", ["email"], name: "index_users_on_email", unique: true
  add_index "user_group_users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
