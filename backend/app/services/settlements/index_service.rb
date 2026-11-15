class Settlements::IndexService
  include CursorPagination

  attr_reader :group_id, :limit, :cursor, :status
  
  def initialize(group_id:, status: nil, limit: DEFAULT_LIMIT, cursor: nil)
    @group_id = group_id
    @status = status
    @limit = limit
    @cursor = cursor
    @errors = []
  end

  def call
    validate
    return { success: false, errors: @errors } unless @errors.empty?
    fetch_settlements

    @has_more = @settlements.size > limit
    @settlements = @settlements.first(limit)
    last_settlement = @settlements.last
    { 
      success: true, 
      settlements: @settlements, 
      pagination: {
        next_cursor: next_cursor(date_key: :settlement_date, date: last_settlement&.settlement_date, record: last_settlement),
        has_more: @has_more
      } 
    }
  end

  private

  def validate
    validate_group
    validate_limit
    validate_cursor
    validate_status
  end

  def validate_group
    if group.blank?
      @errors << "Group is required"
    elsif !group.active?
      @errors << "Group must be active"
    end
  end

  def group
    @group ||= Group.find_by(id: group_id)
  end

  def validate_status
    return if status.blank? || Settlement::STATUS_TYPES.include?(status)

    @errors << "Status must be one of: #{Settlement::STATUS_TYPES.join(', ')}"
  end

  def cursor_date_key
    :settlement_date
  end

  def fetch_settlements
    scope = Settlement.for_group(group.id)

    scope = scope.for_status(status) if status.present?

    if @cursor_date.present? && @cursor_id.present?
      @settlements = scope
       .after_cursor(@cursor_date, @cursor_id)
       .recent_first.limit(limit + 1)
    else
      @settlements = scope.recent_first.limit(limit + 1)
    end
  end
end