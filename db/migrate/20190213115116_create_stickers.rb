class CreateStickers < ActiveRecord::Migration[5.2]
  def change
    create_table :stickers do |t|
      t.string :serial
      t.string :encrypted_serial
      t.integer :batch_id

      t.timestamps
    end
  end
end
