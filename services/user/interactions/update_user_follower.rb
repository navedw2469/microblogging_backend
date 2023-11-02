class UpdateUserFollower < Interaction
  string :performed_by_id
  string :user_id
  boolean :only_data_required, default: true

  def execute
    follower = UserFollower.where(user_id: self.user_id, follower_user_id: self.performed_by_id).first

    if follower.blank?
      self.errors.add(:follower, 'not_found')
      return
    end

    follower.is_active = false

    unless follower.save!
      self.errors.merge!(follower.errors)
      return
    end

    return { id: follower.id } unless self.only_data_required

    return { is_following: follower.is_active }
  end
end