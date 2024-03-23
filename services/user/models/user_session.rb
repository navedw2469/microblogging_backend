class UserSession < DatabaseModel
  belongs_to :user, :class_name => 'User'
end