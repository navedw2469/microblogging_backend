class CreateUserRelatedTables < ActiveRecord::Migration[6.1]
  def change
    create_table :users, id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string :user_name
      t.string :profile_image_url
      t.string :email
      t.string :password_digest
      t.string :full_name
      t.date :dob
      t.string :bio
      t.string :status 
      t.datetime :last_login_time
      t.string :email_token
      t.datetime :last_email_token_sent_at

      t.timestamps
    end

    create_table :user_followers, id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid :user_id
      t.uuid :follower_user_id
      t.boolean :is_active

      t.timestamps
    end
  end
end
