class Memberships::IndexService
  include GroupValidation
  attr_reader :group

  def initialize(group:)
    @group = group
    @errors = []
  end

  def call
    validate_group
    return { success: false, errors: @errors } unless @errors.empty?

    fetch_group_memberships
    { success: true, group_memberships: @group_memberships }
  end

  private

  def fetch_group_memberships
    latest_ids = Membership
      .where(group_id: group.id)
      .group(:user_id)
      .select("MAX(id)")

    @group_memberships = Membership.where(id: latest_ids).order(:id)
  end
end