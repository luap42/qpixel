class Question < Post
  default_scope { where(post_type_id: Question.post_type_id) }

  scope :meta, -> { where(is_meta: true) }
  scope :main, -> { where(is_meta: false) }

  def self.post_type_id
    PostType.mapping['Question']
  end

  def self.list_includes
    includes(:user, user: :avatar_attachment)
  end

  validates :title, :body, :tags_cache, presence: true
  validate :maximum_tags
  validate :maximum_tag_length
  validate :stripped_minimum

  after_save :update_tag_associations

  def answers
    Answer.where(parent: self)
  end

  private

  def update_tag_associations
    tags_cache.each do |tag_name|
      tag = Tag.find_or_create_by name: tag_name
      unless tags.include? tag
        tags << tag
      end
    end

    tags.each do |tag|
      unless tags_cache.include? tag.name
        tags.delete tag
      end
    end
  end

  def maximum_tags
    if tags_cache.length > 5
      errors.add(:tags, "can't have more than 5 tags")
    elsif tags_cache.length < 1
      errors.add(:tags, "must have at least one tag")
    end
  end

  def maximum_tag_length
    tags_cache.each do |tag|
      if tag.length > 20
        errors.add(:tags, "can't be more than 20 characters long each")
      end
    end
  end

  def stripped_minimum
    if body.squeeze("  ").length < 30
      errors.add(:body, "must be more than 30 non-whitespace characters long")
    end
    if title.squeeze("  ").length < 15
      errors.add(:title, "must be more than 15 non-whitespace characters long")
    end
  end
end