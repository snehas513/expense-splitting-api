class Groups::ArchiveService
  include GroupValidation
  attr_reader :user, :group

  def initialize(user:, group:)
    @user = user
    @group = group
    @errors = []
  end

  def call
    validate
    return { success: false, errors: @errors } unless @errors.empty?

    fetch_group
    return { success: false, errors: ["Group not found or you are not an active admin"] } if @group.blank?

    archive_group
    { success: true, group: @group }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end

  private

  def validate
    validate_group
  end

  def fetch_group
    @group = user.groups.find_by(
      id: group.id,
      status: "active",
      memberships: { status: "active", role: "admin" }
    )
  end

  def archive_group
    Group.transaction do
      @group.update!(status: "archived")
      @group.memberships.update!(status: "inactive")
    end
  end
end