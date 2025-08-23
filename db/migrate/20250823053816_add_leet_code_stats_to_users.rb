class AddLeetCodeStatsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :leetcode_solved_count, :integer
    add_column :users, :leetcode_total_count, :integer
    add_column :users, :leetcode_rank, :integer
  end
end
