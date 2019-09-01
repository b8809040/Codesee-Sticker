class AddNoteToBatchRecord < ActiveRecord::Migration[5.2]
  def change
    add_column :batch_records, :note, :string
  end
end
