class CreateUserSessions < ActiveRecord::Migration[6.1]
  def change
    create_table :user_sessions, id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid :user_id
      t.datetime :expiry_time
      t.boolean :is_active

      t.timestamps
    end
  end
end
