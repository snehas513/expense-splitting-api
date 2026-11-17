class Groups::CreateService
  attr_reader :name, :description, :creator
  
  def initialize(name:, description: nil, creator:)
    @name = name
    @description = description
    @creator = creator
  end

  def call
    Group.transaction do
      create_group
      create_memberships
    end
        
    { success: true, group: @group }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end

  private
  
  def create_group
    @group = Group.create!(
      name: name,
      description: description,
      status: "active"
    )
  end

  def create_memberships
    @group.memberships.create!(
      user_id: creator.id, 
      role: "admin",
      status: "active"
    )
  end

end