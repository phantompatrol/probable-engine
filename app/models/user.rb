class User < ActiveRecord::Base
  has_paper_trail

  has_many :groups_users, dependent: :destroy
  has_many :groups, through: :groups_users
  has_many :permissions, -> { uniq }, through: :groups

  validates :first_name, :last_name, :spire_id, :phone, :email, presence: true
  validates :spire_id, uniqueness: true

  scope :active, -> { where(active: true) }

  def full_name
    [first_name, last_name].join ' '
  end

  # Can take 1, 2, or 3 params
  # 1 param -> has_permission?(permission_object)
  # 2-3 params -> has_permission?(controller, action, id=nil)
  def has_permission?(controller, action, id)
    # def has_permission?(controller, action, id=nil)
    # return permissions.include? args[0] if args.size == 1

    # controller = args[0]
    # action = args[1]
    # id = args[2]

    # Allow anyone to access the home page
    return true if (controller == 'application' && action == 'root') || (controller == 'home' && action == 'index')

    # Get a list of permissions associated with this controller and action
    relevant_permissions = permissions.where(controller: controller, action: action)

    # Deny if the list is empty
    return false if relevant_permissions.empty?

    # Permit if list has a permission with no id_field
    return true if relevant_permissions.where(id_field: nil).present?

    # Permit if the list has a permission with an id field, and the model instance we want matches
    model = controller.classify.constantize

    relevant_permissions.each do |perm|
      id_field_val = model.find(id).send(perm[:id_field])

      return true if id_field_val == self.id || (id_field_val.methods.include?(:include?) && id_field_val.include?(self))
    end

    # Deny if everything fails
    false
  end

  def has_group?(group)
    groups.include? group
  end
end
