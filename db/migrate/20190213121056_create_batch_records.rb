class CreateBatchRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :batch_records do |t|
      t.integer :sticker_id
      t.integer :amount

      t.timestamps
    end
  end
end
