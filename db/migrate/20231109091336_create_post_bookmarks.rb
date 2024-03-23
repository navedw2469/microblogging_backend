class CreatePostBookmarks < ActiveRecord::Migration[6.1]
  def change
    create_table :post_bookmarks, id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid :post_id
      t.uuid :user_id
      t.boolean :is_active

      t.timestamps
    end
  end
end
