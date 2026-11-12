class Expenses::IndexService
  attr_reader :group_id, :limit, :cursor
  MAX_CURSOR_ID = 9_223_372_036_854_775_807
  DEFAULT_LIMIT = 20
  MIN_LIMIT = 1
  MAX_LIMIT = 100
  
  def initialize(group_id:, limit: DEFAULT_LIMIT, cursor: nil)
    @group_id = group_id
    @limit = limit
    @cursor = cursor
    @errors = []
  end

  def call
    validate
    return { success: false, errors: @errors } unless @errors.empty?
    fetch_expenses

    @has_more = @expenses.size > limit
    @expenses = @expenses.first(limit)

    { 
      success: true, 
      expenses: @expenses, 
      pagination: {
        next_cursor: next_cursor,
        has_more: @has_more
      } 
    }
  end

  private

  def validate
    validate_group
    validate_limit
    validate_cursor
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

  def validate_limit
    if limit.blank?
      @errors << "Limit is required"
      return
    end

    begin
      value = Integer(limit.to_s)
    rescue ArgumentError, TypeError
      @errors << "Limit must be a valid integer"
      return
    end

    unless value.positive?
      @errors << "Limit must be a positive integer"
      return
    end

    if value > MAX_LIMIT
      @errors << "Limit exceeds the maximum allowed value #{MAX_LIMIT}"
      return
    end
    @limit = value
  end

  def validate_cursor
    @cursor_date = nil
    @cursor_id = nil

    cursor_data = decode_cursor(cursor)

    if cursor.present? && cursor_data.nil?
      @errors << "Cursor data is malformed"
      return
    end

    if cursor.present?
      date_string = cursor_data["expense_date"]

      if date_string.blank?
        @errors << "Expense date is missing"
        return
      end

      cursor_date = parse_date(date_string)

      if cursor_date.nil?
        @errors << "Expense date is invalid"
        return
      end
    end

    if cursor.present?
      cursor_id = cursor_data["id"]

      if cursor_id.blank?
        @errors << "Cursor ID is missing"
        return
      end

      begin
        value = Integer(cursor_id.to_s)
      rescue ArgumentError, TypeError
        @errors << "Cursor ID must be a valid integer"
        return
      end

      unless value.positive?
        @errors << "Cursor ID must be a positive integer"
        return
      end

      if value > MAX_CURSOR_ID
        @errors << "Cursor ID exceeds the maximum allowed value"
        return
      end
    end
    @cursor_date = cursor_date
    @cursor_id = value
  end

  def decode_cursor(cursor)
    return nil if cursor.blank?

    decoded = Base64.urlsafe_decode64(cursor)
    data = JSON.parse(decoded)
    data.is_a?(Hash) ? data : nil
  rescue ArgumentError, JSON::ParserError, TypeError
    nil
  end

  def encode_cursor(expense)
    data = { expense_date: expense.expense_date, id: expense.id }
    Base64.urlsafe_encode64(JSON.generate(data))
  end

  def parse_date(date_string)
    begin
      Date.iso8601(date_string)
    rescue Date::Error
      nil
    end
  end

  def fetch_expenses
    scope = Expense.active.for_group(group.id)

    if @cursor_date.present? && @cursor_id.present?
      @expenses = scope
       .after_cursor(@cursor_date, @cursor_id)
       .recent_first.limit(limit + 1)
    else
      @expenses = scope.recent_first.limit(limit + 1)
    end
  end

  def next_cursor
    return nil unless @has_more

    last_expense = @expenses.last
    encode_cursor(last_expense)
  end
end