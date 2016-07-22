class CreateRequests < ActiveRecord::Migration
  def change
    if !table_exists?("requests")
      create_table :requests do |t|
        t.timestamps null: false
      end
    end
  end
end
