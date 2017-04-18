class Project < ActiveRecord::Base
  has_many :projects_users, class_name: "ProjectsUsers",
                            foreign_key: "project_id",
                            dependent: :destroy
  has_many :users, through: :projects_users

  has_many :owners, -> { where(owner: true) }, class_name: 'ProjectsUsers'
  has_many :members, -> { where(owner: false) }, class_name: 'ProjectsUsers'

  has_many :merge_requests, dependent: :destroy

  validates :name, presence: true
  validates :linter, format: { with: %r{\A[^\./](?!.*(\.\.|[&|<>])).*\z},
                               message: "can't have pipes, dots, slashes, two dots, etc, try to use a script in your " \
                                        'project directory' },
                     allow_blank: true
  validate :validate_repository

  def gitlab_ci?
    !gitlab_ci_project_url.blank?
  end

  def configuration_hash
    Digest::MD5.hexdigest(linter)
  end

  def update_users!(owners, members)
    raise ActiveRecord::RecordNotSaved, 'Project must have a owner.' if owners.empty?

    # if the user is on the owner list remove it from member list
    members.delete_if { |m| owners.include?(m) }

    # remove previous users
    projects_users.clear()

    set_users(members, false)
    set_users(owners, true)
  end

  def owner?(who)
    return who.nil? ? false : owners.exists?(user_id: who.id)
  end

  private

  def set_users(users, is_owner)
    users.each do |user|
      ProjectsUsers.create(project_id: id, user_id: user.id, owner: is_owner)
    end
  end

  def validate_repository
    is_valid = URI.regexp =~ repository && /\A[^ ;&|]+\z/ =~ repository
    errors.add(:repository, 'is not a valid URI') unless is_valid
  end
end
