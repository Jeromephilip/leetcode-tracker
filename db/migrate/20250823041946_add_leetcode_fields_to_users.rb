class AddLeetcodeFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :leetcode_username, :string
    add_column :users, :leetcode_cookies, :text
    add_column :users, :leetcode_last_sync, :datetime
  end
end
