class LoginUser < Interaction
  string :user_name
  string :password

  def execute
    user = get_user

    if user.blank?
      self.errors.add(:user, 'not found')
      return
    end

    unless user.authenticate(self.password)
      self.errors.add(:password, 'is incorrect')
      return
    end

    session = user.sessions.new({ is_active: true, expiry_time: Time.now + 1.day })

    unless session.save!
      self.errors.merge!(session.errors)
      return
    end

    { session_token: session.id, user: user.as_json.deep_symbolize_keys.slice(:id, :user_name, :profile_image_url, :email, :full_name, :dob, :bio) } 
  end

  def get_user
    return User.find_by(user_name: self.user_name) || User.find_by(email: self.user_name) if self.user_name.present?

    User.where(email: self.email).first
  end
end