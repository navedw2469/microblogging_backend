class UpdatePostLike < Interaction
  string :performed_by_id
  string :post_id
  boolean :only_data_required, default: true

  def execute
    like = PostLike.find_by(user_id: self.performed_by_id, post_id: self.post_id)
    
    if like.blank?
      self.errors.add(:like, 'not found')
      return
    end

    unless like.update!({ is_active: false })
      self.errors.merge!(like.errors)
      return
    end

    return { id: like.id } unless self.only_data_required

    return { is_liked: false, likes_count: PostLike.where(post_id: like.post_id, is_active: true).count }
  end
end