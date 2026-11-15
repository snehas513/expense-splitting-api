module DateParser
  private

  def parse_date(date)
    return date if date.is_a?(Date)
    return nil unless date.is_a?(String)

    Date.iso8601(date)
  rescue Date::Error
    nil
  end
end