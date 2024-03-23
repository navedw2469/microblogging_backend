class User < DatabaseModel
  has_secure_password

  has_many :sessions, class_name: 'UserSession'
  accepts_nested_attributes_for :sessions

  validates :email, presence: true, format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i, message: 'is not a valid email address' }

  validates_uniqueness_of :email, :user_name

  PASSWORD_FORMAT = /\A(?=.{8,})(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#$%^&*])/x

  validates :password, format: { with: PASSWORD_FORMAT, message: 'should contain at least 8 characters, a digit, a lowercase letter, an uppercase letter, and one of !@#$%^&* ' }, allow_nil: true

  has_many :followers, class_name: 'UserFollower'
end