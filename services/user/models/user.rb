class User < DatabaseModel
  has_secure_password

  has_many :sessions, class_name: 'UserSession'
  accepts_nested_attributes_for :sessions

  has_many :followers, class_name: 'UserFollower'
end