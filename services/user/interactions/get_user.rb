class GetUser < Interaction
  string :user_name

  def execute
    user = User.where(user_name: self.user_name).first

    if user.blank?
      self.errors.add(:user_name, "Not Found")
      return
    end

    return {
      data: user.as_json.deep_symbolize_keys.except(:email, :password)
    }
  end
end