class UpdatePostLike < Interaction
  string :user_id
  string :post_id

  def execute
    like = PostLike.find_by(user_id: self.user_id, post_id: self.post_id)
    
    if like.blank?
      self.errors.add(:like, 'not found')
      return
    end

    unless like.update!({ is_active: false })
      self.errors.merge!(like.errors)
      return
    end

    return { id: like.id }
  end
end