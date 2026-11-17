class Groups::UpdateService
  attr_reader :user, :group, :attributes

  def initialize(user:, group:, attributes:)
    @user = user
    @group = group
    @attributes = attributes
    @errors = []
  end

  def call
    validate
    return { success: false, errors: @errors } unless @errors.empty?

    fetch_group
    return { success: false, errors: ["Group not found"] } if @group.blank?

    update_group
    { success: true, group: @group }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end

  private

  def validate
    validate_group
    validate_attributes
  end

  def validate_group
    if group.blank?
      @errors << "Group is required"
    elsif !group.active?
      @errors << "Group must be active"
    end
  end

  def validate_attributes
  if !attributes.is_a?(Hash) || attributes.empty?
    @errors << "Valid update attributes are required"
  end
end

  def fetch_group
    @group = user.groups.find_by(
      id: group.id,
      status: "active",
      memberships: { status: "active", role: "admin" }
    )
  end

  def update_group
    @group.update!(attributes)
  end
end