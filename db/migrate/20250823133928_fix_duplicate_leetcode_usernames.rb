class FixDuplicateLeetcodeUsernames < ActiveRecord::Migration[8.0]
  def up
    duplicates = User.where.not(leetcode_username: [nil, ''])
                     .group(:leetcode_username)
                     .having('COUNT(*) > 1')
                     .pluck(:leetcode_username)
    
    puts "Found #{duplicates.count} duplicate leetcode usernames: #{duplicates.join(', ')}"
    
    duplicates.each do |username|
      users_with_username = User.where(leetcode_username: username).order(:created_at)
      users_to_clean = users_with_username.offset(1)
      
      users_to_clean.each do |user|
        puts "Cleaning up duplicate leetcode username '#{username}' for user #{user.email}"
        user.update!(
          leetcode_username: nil,
          leetcode_cookies: nil,
          leetcode_last_sync: nil,
          leetcode_solved_count: nil,
          leetcode_total_count: nil,
          leetcode_rank: nil
        )
      end
    end
    
    add_index :users, :leetcode_username, unique: true, where: "leetcode_username IS NOT NULL"
  end

  def down
    remove_index :users, :leetcode_username
  end
end
