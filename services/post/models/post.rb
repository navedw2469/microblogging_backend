class Post < DatabaseModel
  has_many :likes, :class_name => 'PostLike'
  has_many :bookmarks, :class_name => 'PostBookmark'
end
