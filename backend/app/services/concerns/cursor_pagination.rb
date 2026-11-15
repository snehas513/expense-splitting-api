module CursorPagination
  include DateParser
  
  MAX_CURSOR_ID = 9_223_372_036_854_775_807
  DEFAULT_LIMIT = 20
  MIN_LIMIT = 1
  MAX_LIMIT = 100

  private

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

    cursor_date = nil
    value = nil

    cursor_data = decode_cursor(cursor)

    if cursor.present? && cursor_data.nil?
      @errors << "Cursor data is malformed"
      return
    end

    if cursor.present?
      date_string = cursor_data[cursor_date_key.to_s]

      if date_string.blank?
        @errors << "Cursor date is missing"
        return
      end

      cursor_date = parse_date(date_string)

      if cursor_date.nil?
        @errors << "Cursor date is invalid"
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

  def cursor_date_key
    raise NotImplementedError
  end

  def decode_cursor(cursor)
    return nil if cursor.blank?

    decoded = Base64.urlsafe_decode64(cursor)
    data = JSON.parse(decoded)
    data.is_a?(Hash) ? data : nil
  rescue ArgumentError, JSON::ParserError, TypeError
    nil
  end

  def encode_cursor(data)
    Base64.urlsafe_encode64(JSON.generate(data))
  end

  def next_cursor(date_key:, date:, record:)
    return nil unless @has_more && record.present?

    data = { date_key.to_sym => date, id: record.id }
    encode_cursor(data)
  end
end
