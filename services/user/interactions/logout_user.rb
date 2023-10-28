class LogoutUser < Interaction
  string :session_token

  def execute
    session = UserSession.where(id: session_token).first

    if session.blank?
      self.errors.add(:session_token, 'not found')
      return
    end

    session.is_active = false

    unless session.save!
      self.errors.add(session.errors)
      return
    end


    { logout: true }
  end
end