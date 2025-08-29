class AddLeetcodeNotesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :leetcode_notes, :text
  end
end
