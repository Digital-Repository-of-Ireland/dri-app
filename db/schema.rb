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

ActiveRecord::Schema.define(version: 20160725133248) do

  create_table "bookmarks", force: :cascade do |t|
    t.integer  "user_id",       null: false
    t.string   "document_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type"
    t.string   "document_type"
  end

  add_index "bookmarks", ["user_id"], name: "index_bookmarks_on_user_id"

  create_table "brands", force: :cascade do |t|
    t.string   "filename"
    t.string   "content_type"
    t.binary   "file_contents"
    t.integer  "institute_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "brands", ["institute_id"], name: "index_brands_on_institute_id"

  create_table "datacite_dois", force: :cascade do |t|
    t.string   "object_id"
    t.string   "modified"
    t.string   "mod_version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "update_type"
    t.integer  "version"
  end

  create_table "doi_metadata", force: :cascade do |t|
    t.integer  "datacite_doi_id"
    t.text     "title"
    t.text     "creator"
    t.text     "subject"
    t.text     "description"
    t.text     "rights"
    t.text     "creation_date"
    t.text     "published_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "doi_metadata", ["datacite_doi_id"], name: "index_doi_metadata_on_datacite_doi_id"

  create_table "ingest_batches", force: :cascade do |t|
    t.string   "email"
    t.text     "media_object_ids"
    t.boolean  "finished",         default: false
    t.boolean  "email_sent",       default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_ingest_id"
    t.string   "collection_id"
  end

  create_table "ingest_statuses", force: :cascade do |t|
    t.string   "batch_id"
    t.string   "asset_id"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "asset_type"
  end

  add_index "ingest_statuses", ["asset_id"], name: "index_ingest_statuses_on_asset_id"
  add_index "ingest_statuses", ["batch_id"], name: "index_ingest_statuses_on_batch_id"

  create_table "institutes", force: :cascade do |t|
    t.string   "name"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "logo"
  end

  add_index "institutes", ["name"], name: "index_institutes_on_name"

  create_table "job_statuses", force: :cascade do |t|
    t.integer  "ingest_status_id"
    t.string   "job"
    t.string   "status"
    t.string   "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "job_statuses", ["ingest_status_id"], name: "index_job_statuses_on_ingest_status_id"

  create_table "licences", force: :cascade do |t|
    t.string   "name"
    t.string   "url"
    t.string   "logo"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "local_files", force: :cascade do |t|
    t.string  "path"
    t.string  "fedora_id"
    t.string  "ds_id"
    t.string  "mime_type"
    t.integer "version"
    t.text    "checksum"
  end

  create_table "master_files", force: :cascade do |t|
    t.integer  "media_object_id"
    t.string   "status_code"
    t.string   "file_size"
    t.string   "file_location"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.boolean  "metadata"
    t.boolean  "preservation"
  end

  add_index "master_files", ["media_object_id"], name: "index_master_files_on_media_object_id"

  create_table "media_objects", force: :cascade do |t|
    t.string   "collection"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "searches", force: :cascade do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type"
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id"

  create_table "user_background_tasks", force: :cascade do |t|
    t.integer "user_id"
    t.string  "job"
    t.string  "name"
    t.string  "message"
    t.string  "status"
  end

  create_table "user_group_authentications", force: :cascade do |t|
    t.integer "user_id"
    t.string  "provider"
    t.string  "uid"
  end

  create_table "user_group_groups", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_locked",    default: false
    t.boolean  "reader_group", default: false
  end

  add_index "user_group_groups", ["name"], name: "index_user_group_groups_on_name", unique: true

  create_table "user_group_memberships", force: :cascade do |t|
    t.integer  "group_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "approved_by"
    t.text     "request_form"
  end

  add_index "user_group_memberships", ["group_id", "user_id"], name: "index_user_group_memberships_on_group_id_and_user_id", unique: true

  create_table "user_group_users", force: :cascade do |t|
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
    t.datetime "created_at"
    t.datetime "updated_at"
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

  add_index "user_group_users", ["authentication_token"], name: "index_user_group_users_on_authentication_token", unique: true
  add_index "user_group_users", ["confirmation_token"], name: "index_user_group_users_on_confirmation_token", unique: true
  add_index "user_group_users", ["email"], name: "index_user_group_users_on_email", unique: true
  add_index "user_group_users", ["reset_password_token"], name: "index_user_group_users_on_reset_password_token", unique: true

  create_table "user_ingests", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "user_ingests", ["user_id"], name: "index_user_ingests_on_user_id"

  create_table "version_committers", force: :cascade do |t|
    t.string   "obj_id"
    t.string   "datastream_id"
    t.string   "version_id"
    t.string   "committer_login"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"

end
