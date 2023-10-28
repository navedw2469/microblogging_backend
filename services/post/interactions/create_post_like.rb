class CreatePostLike < Interaction
  string :user_id
  string :post_id

  def execute
    like = PostLike.find_or_initialize_by(user_id: self.user_id, post_id: self.post_id)
    like.is_active = true

    unless like.save!
      self.errors.merge!(like.errors)
      return
    end

    return { id: like.id }
  end
end