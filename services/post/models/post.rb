class Post < DatabaseModel
  has_many :likes, :class_name => 'PostLike'
end
