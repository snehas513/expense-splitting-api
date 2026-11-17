class Groups::ShowService
  attr_reader :user, :group

  def initialize(user:, group:)
    @user = user
    @group = group
    @errors = []
  end

  def call
    validate_group
    return { success: false, errors: @errors } unless @errors.empty?

    fetch_group
    return { success: false, errors: ["Group not found"] } if @group.blank?

    { success: true, group: @group }
  end

  private

  def validate_group
    if group.blank?
      @errors << "Group is required"
    elsif !group.active?
      @errors << "Group must be active"
    end
  end

  def fetch_group
    @group = user.groups.find_by(
      id: group.id,
      status: "active",
      memberships: { status: "active" }
    )
  end
end