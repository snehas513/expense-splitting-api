class Expenses::IndexService
  include GroupValidation
  include CursorPagination

  attr_reader :group_id, :limit, :cursor
    
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
    last_expense = @expenses.last
    { 
      success: true, 
      expenses: @expenses, 
      pagination: {
        next_cursor: next_cursor(date_key: :expense_date, date: last_expense&.expense_date, record: last_expense),
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

  def group
    @group ||= Group.find_by(id: group_id)
  end

  def cursor_date_key
    :expense_date
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
end