class GetUser < Interaction
  string :user_name
  string :performed_by_id

  def execute
    user = User.where(user_name: self.user_name).first

    if user.blank?
      self.errors.add(:user_name, "Not Found")
      return
    end

    followers_count = user.followers.joins("inner join users on user_followers.follower_user_id = users.id and users.status='active' and user_followers.is_active = true").count
    following_count = UserFollower.where(follower_user_id: user.id, is_active: true).count

    return {
      data: user.as_json.deep_symbolize_keys.except(:email, :password_digest).merge!({followers_count: followers_count, following_count: following_count})
    }
  end
end