class GetUserSession < Interaction
  string :session_token

  def execute
    session = UserSession.where(id: session_token, is_active: true).where('expiry_time > ?', Time.now).first

    return {} if session.blank?
    
    { user: get_data(session) }
  end

  def get_data(session)
    session.user.as_json.deep_symbolize_keys.slice(:id, :user_name, :profile_image_url, :email, :full_name, :dob, :bio)
  end
end