class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users, id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      
      t.timestamps
    end
  end
end
