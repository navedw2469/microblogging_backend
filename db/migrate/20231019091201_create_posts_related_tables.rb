class CreatePostsRelatedTables < ActiveRecord::Migration[6.1]
  def change
    create_table :posts, id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid :user_id
      t.string :text
      t.string :image_url
      t.string :video_url
      t.uuid :parent_post_id

      t.timestamps
    end

    create_table :post_likes, id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid :post_id
      t.uuid :user_id
      t.boolean :is_active
  
      t.timestamps
    end
  end
end
