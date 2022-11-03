# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_10_20_143340) do

  create_table "aggregations", force: :cascade do |t|
    t.string "collection_id"
    t.string "aggregation_id"
    t.boolean "doi_from_metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "iiif_main"
    t.string "comment"
    t.index ["collection_id"], name: "index_aggregations_on_collection_id", unique: true
  end

  create_table "bookmarks", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "document_id"
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "user_type"
    t.string "document_type"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "brands", force: :cascade do |t|
    t.string "filename"
    t.string "content_type"
    t.binary "file_contents", limit: 1048576
    t.integer "institute_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["institute_id"], name: "index_brands_on_institute_id"
  end

  create_table "collection_locks", force: :cascade do |t|
    t.string "collection_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "datacite_dois", force: :cascade do |t|
    t.string "object_id"
    t.string "modified"
    t.string "mod_version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "update_type"
    t.integer "version"
    t.string "status"
  end

  create_table "doi_metadata", force: :cascade do |t|
    t.integer "datacite_doi_id"
    t.text "title"
    t.text "creator"
    t.text "subject"
    t.text "description"
    t.text "rights"
    t.text "creation_date"
    t.text "published_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["datacite_doi_id"], name: "index_doi_metadata_on_datacite_doi_id"
  end

  create_table "dri_access_controls", force: :cascade do |t|
    t.string "master_file_access"
    t.text "discover_users"
    t.text "discover_groups"
    t.text "read_users"
    t.text "read_groups"
    t.text "edit_users"
    t.text "edit_groups"
    t.text "manager_users"
    t.text "manager_groups"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "digital_object_type"
    t.integer "digital_object_id"
    t.index ["digital_object_type", "digital_object_id"], name: "do_acl_idx"
  end

  create_table "dri_batch_ingest_ingest_batches", force: :cascade do |t|
    t.string "email"
    t.string "collection_id"
    t.integer "user_ingest_id"
    t.text "media_object_ids"
    t.boolean "finished", default: false
    t.boolean "email_sent", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "dri_batch_ingest_master_files", force: :cascade do |t|
    t.integer "media_object_id"
    t.string "status_code"
    t.string "file_size"
    t.text "file_location"
    t.boolean "preservation"
    t.text "download_spec"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "metadata"
    t.index ["media_object_id"], name: "index_dri_batch_ingest_master_files_on_media_object_id"
  end

  create_table "dri_batch_ingest_media_objects", force: :cascade do |t|
    t.integer "ingest_batch_id"
    t.string "collection"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingest_batch_id"], name: "ingest_batch_idx"
  end

  create_table "dri_batch_ingest_user_ingests", force: :cascade do |t|
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_dri_batch_ingest_user_ingests_on_user_id"
  end

  create_table "dri_collection_relationships", force: :cascade do |t|
    t.integer "digital_object_id"
    t.integer "collection_relative_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dri_digital_objects", force: :cascade do |t|
    t.string "ingest_files_from_metadata"
    t.string "published_at"
    t.string "digital_object_type"
    t.string "governing_collection_type"
    t.integer "governing_collection_id"
    t.string "previous_sibling_type"
    t.integer "previous_sibling_id"
    t.string "documentation_for_type"
    t.integer "documentation_for_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "metadata_checksum"
    t.integer "object_version"
    t.string "status"
    t.string "depositor"
    t.string "model_version"
    t.string "verified"
    t.string "doi"
    t.string "cover_image"
    t.string "institute"
    t.string "depositing_institute"
    t.string "licence"
    t.index ["documentation_for_type", "documentation_for_id"], name: "doc_for_index"
    t.index ["governing_collection_type", "governing_collection_id"], name: "governing_index"
    t.index ["metadata_checksum"], name: "metadata_chksm_index"
    t.index ["previous_sibling_type", "previous_sibling_id"], name: "sibling_index"
  end

  create_table "dri_generic_files", force: :cascade do |t|
    t.text "title"
    t.text "creator"
    t.string "filename"
    t.string "label"
    t.string "depositor"
    t.string "mime_type"
    t.integer "version"
    t.string "path"
    t.string "checksum_md5"
    t.string "checksum_sha256"
    t.string "checksum_rmd160"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "digital_object_type"
    t.integer "digital_object_id"
    t.boolean "preservation_only"
    t.index ["digital_object_type", "digital_object_id"], name: "gf_do_idx"
  end

  create_table "dri_identifiers", force: :cascade do |t|
    t.string "alternate_id"
    t.string "identifiable_type"
    t.integer "identifiable_id"
    t.index ["alternate_id"], name: "index_dri_identifiers_on_alternate_id", unique: true
    t.index ["identifiable_type", "identifiable_id"], name: "index_dri_identifiers_on_identifiable_type_and_identifiable_id"
  end

  create_table "dri_linked_data", force: :cascade do |t|
    t.text "title"
    t.string "creator"
    t.string "resource_type"
    t.string "identifier"
    t.string "source"
    t.text "spatial"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "dri_om_datastreams", force: :cascade do |t|
    t.string "type"
    t.binary "datastream_content", limit: 16777216
    t.string "describable_type"
    t.integer "describable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["describable_type", "describable_id"], name: "om_index"
  end

  create_table "dri_reconciliation_results", force: :cascade do |t|
    t.string "object_id"
    t.string "uri"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fixity_checks", force: :cascade do |t|
    t.string "collection_id"
    t.string "object_id"
    t.boolean "verified"
    t.text "result"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "fixity_report_id"
    t.index ["collection_id"], name: "index_fixity_checks_on_collection_id"
    t.index ["fixity_report_id"], name: "index_fixity_checks_on_fixity_report_id"
    t.index ["object_id"], name: "index_fixity_checks_on_object_id"
  end

  create_table "fixity_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "collection_id"
    t.index ["collection_id"], name: "index_fixity_reports_on_collection_id"
  end

  create_table "ingest_statuses", force: :cascade do |t|
    t.string "batch_id"
    t.string "asset_id"
    t.string "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "asset_type"
    t.index ["asset_id"], name: "index_ingest_statuses_on_asset_id"
    t.index ["batch_id"], name: "index_ingest_statuses_on_batch_id"
  end

  create_table "institutes", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "logo"
    t.boolean "depositing"
    t.index ["name"], name: "index_institutes_on_name"
  end

  create_table "job_statuses", force: :cascade do |t|
    t.integer "ingest_status_id"
    t.string "job"
    t.string "status"
    t.text "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["ingest_status_id"], name: "index_job_statuses_on_ingest_status_id"
  end

  create_table "licences", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.string "logo"
    t.string "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "organisation_users", force: :cascade do |t|
    t.integer "institute_id"
    t.integer "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["institute_id", "user_id"], name: "index_organisation_users_on_institute_id_and_user_id", unique: true
  end

  create_table "qa_local_authorities", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_qa_local_authorities_on_name", unique: true
  end

  create_table "qa_local_authority_entries", force: :cascade do |t|
    t.integer "local_authority_id"
    t.string "label"
    t.string "uri"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["local_authority_id"], name: "index_qa_local_authority_entries_on_local_authority_id"
    t.index ["uri"], name: "index_qa_local_authority_entries_on_uri", unique: true
  end

  create_table "searches", force: :cascade do |t|
    t.text "query_params"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "user_type"
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "tp_items", primary_key: "item_id", id: :string, force: :cascade do |t|
    t.string "story_id"
    t.date "start_date"
    t.date "end_date"
    t.string "item_link"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "tp_people", primary_key: "person_id", id: :string, force: :cascade do |t|
    t.string "item_id"
    t.string "first_name"
    t.string "last_name"
    t.string "birth_place"
    t.date "birth_date"
    t.string "death_place"
    t.date "death_date"
    t.string "person_description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "tp_places", primary_key: "place_id", id: :string, force: :cascade do |t|
    t.string "item_id"
    t.string "place_name"
    t.float "latitude"
    t.float "longitude"
    t.string "wikidata_id"
    t.string "wikidata_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "tp_stories", primary_key: "story_id", id: :string, force: :cascade do |t|
    t.string "dri_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "user_background_tasks", force: :cascade do |t|
    t.integer "user_id"
    t.string "job"
    t.string "name"
    t.string "message"
    t.string "status"
  end

  create_table "user_group_authentications", force: :cascade do |t|
    t.integer "user_id"
    t.string "provider"
    t.string "uid"
  end

  create_table "user_group_groups", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "is_locked", default: false
    t.boolean "reader_group", default: false
    t.index ["name"], name: "index_user_group_groups_on_name", unique: true
  end

  create_table "user_group_memberships", force: :cascade do |t|
    t.integer "group_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "approved_by"
    t.text "request_form"
    t.index ["group_id", "user_id"], name: "index_user_group_memberships_on_group_id_and_user_id", unique: true
  end

  create_table "user_group_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "authentication_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "first_name"
    t.string "second_name"
    t.string "locale"
    t.boolean "guest", default: false
    t.integer "view_level", default: 0
    t.string "about_me", default: ""
    t.datetime "token_creation_date"
    t.string "image_link"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.index ["authentication_token"], name: "index_user_group_users_on_authentication_token", unique: true
    t.index ["confirmation_token"], name: "index_user_group_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_user_group_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_user_group_users_on_reset_password_token", unique: true
  end

  create_table "version_committers", force: :cascade do |t|
    t.string "obj_id"
    t.string "datastream_id"
    t.string "version_id"
    t.string "committer_login"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "dri_batch_ingest_master_files", "dri_batch_ingest_media_objects", column: "media_object_id"
  add_foreign_key "dri_batch_ingest_media_objects", "dri_batch_ingest_ingest_batches", column: "ingest_batch_id"
  add_foreign_key "dri_batch_ingest_user_ingests", "user_group_users", column: "user_id"
  add_foreign_key "fixity_checks", "fixity_reports"
  add_foreign_key "qa_local_authority_entries", "qa_local_authorities", column: "local_authority_id"
  add_foreign_key "tp_items", "tp_stories", column: "story_id", primary_key: "story_id"
  add_foreign_key "tp_people", "tp_items", column: "item_id", primary_key: "item_id"
  add_foreign_key "tp_places", "tp_items", column: "item_id", primary_key: "item_id"
end
