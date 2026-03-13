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

ActiveRecord::Schema[8.0].define(version: 2026_03_02_084514) do
  create_table "channels", force: :cascade do |t|
    t.string "name"
    t.integer "chat_server_id", null: false
    t.integer "position"
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_server_id"], name: "index_channels_on_chat_server_id"
  end

  create_table "chat_servers", force: :cascade do |t|
    t.string "name"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "typing_users"
    t.integer "owner_id"
    t.string "encryption_key"
  end

  create_table "direct_messages", force: :cascade do |t|
    t.integer "sender_id"
    t.integer "recipient_id"
    t.text "content"
    t.boolean "encrypted"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invites", force: :cascade do |t|
    t.string "code"
    t.integer "chat_server_id", null: false
    t.datetime "expires_at"
    t.integer "uses_left"
    t.integer "creator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_server_id"], name: "index_invites_on_chat_server_id"
  end

  create_table "mentions", force: :cascade do |t|
    t.integer "message_id", null: false
    t.integer "mentioned_user_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mentioned_user_id"], name: "index_mentions_on_mentioned_user_id"
    t.index ["message_id"], name: "index_mentions_on_message_id"
    t.index ["user_id"], name: "index_mentions_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.string "username"
    t.string "room"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "chat_server_id"
    t.integer "channel_id"
    t.boolean "pinned"
    t.integer "user_id"
  end

  create_table "poll_votes", force: :cascade do |t|
    t.integer "poll_id", null: false
    t.integer "user_id", null: false
    t.integer "option_index"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["poll_id"], name: "index_poll_votes_on_poll_id"
    t.index ["user_id"], name: "index_poll_votes_on_user_id"
  end

  create_table "polls", force: :cascade do |t|
    t.string "question"
    t.text "options"
    t.integer "message_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_polls_on_message_id"
  end

  create_table "reactions", force: :cascade do |t|
    t.string "emoji"
    t.integer "message_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "user_id", "emoji"], name: "index_reactions_on_unique_combination", unique: true
    t.index ["message_id"], name: "index_reactions_on_message_id"
    t.index ["user_id"], name: "index_reactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar_url"
    t.string "status"
    t.string "rich_presence"
    t.text "bio"
    t.string "api_token"
    t.string "role", default: "user"
    t.string "encryption_key"
    t.string "public_key"
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
  end

  add_foreign_key "channels", "chat_servers"
  add_foreign_key "invites", "chat_servers"
  add_foreign_key "mentions", "mentioned_users"
  add_foreign_key "mentions", "messages"
  add_foreign_key "mentions", "users"
  add_foreign_key "poll_votes", "polls"
  add_foreign_key "poll_votes", "users"
  add_foreign_key "polls", "messages"
  add_foreign_key "reactions", "messages"
  add_foreign_key "reactions", "users"
end
