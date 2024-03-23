class PostBookmark < DatabaseModel
  belongs_to :post, :class_name => 'Post'
end