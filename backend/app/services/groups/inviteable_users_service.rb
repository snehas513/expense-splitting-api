class Groups::InviteableUsersService
  include GroupValidation

  attr_reader :user, :group, :query

  def initialize(user:, group:, query: nil)
    @user = user
    @group = group
    @query = query&.strip
    @errors = []
  end

  def call
    validate
    return { success: false, errors: @errors } unless @errors.empty?

    { success: true, users: fetch_users }
  end

  private

  def validate
    validate_user
    validate_group
    validate_admin_membership
  end

  def validate_user
    if user.blank?
      @errors << "User is required"
    elsif !user.active?
      @errors << "User must have an active account"
    end
  end

  def validate_admin_membership
    return if user.blank? || group.blank?

    membership = Membership.find_by(
      user_id: user.id,
      group_id: group.id,
      status: "active",
      role: "admin"
    )

    @errors << "User is not an active admin member of the group" if membership.blank?
  end

  def fetch_users
    users = User.where(status: "active")
                .where.not(id: user.id)
                .where.not(
                  id: Membership.where(
                    group_id: group.id,
                    status: "active"
                  ).select(:user_id)
                )
                .where.not(
                  id: Invitation.where(
                    group_id: group.id,
                    status: "pending"
                  ).select(:invited_user_id)
                )

    if query.present?
      users = users.where(
        "name LIKE :query OR email LIKE :query",
        query: "%#{query}%"
      )
    end

    users.order(:name).limit(20).as_json(only: [:id, :name, :email])
  end
end