class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :submissions, dependent: :destroy

  validates :leetcode_username, uniqueness: { scope: :id, allow_blank: true }
  validate :leetcode_username_not_already_taken, if: :leetcode_username_changed?

  def leetcode_username_not_already_taken
    return if leetcode_username.blank?

    existing_user = User.where(leetcode_username: leetcode_username).where.not(id: id).first
    if existing_user
      errors.add(:leetcode_username, "is already linked to another account (#{existing_user.email})")
    end
  end

  def self.leetcode_username_available?(username)
    return false if username.blank?
    !where(leetcode_username: username).exists?
  end

  def self.find_by_leetcode_username(username)
    where(leetcode_username: username).first
  end
end
