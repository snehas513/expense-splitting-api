class Groups::IndexService
  attr_reader :user

  def initialize(user:)
    @user = user
  end

  def call
    fetch_groups
    { success: true, groups: @groups }
  end

  private

  def fetch_groups
    @groups = user.groups.where(
      status: "active",
      memberships: { status: "active" }
    )
  end
end