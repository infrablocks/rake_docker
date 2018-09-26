require 'json'
require 'colored2'

module DockerOutput
  def self.parse(chunk)
    chunk.each_line do |line|
      yield self.parse_line(line)
    end
  end

  def self.parse_line(line)
    begin
      json = JSON.parse(line.strip)
    rescue JSON::ParserError
      return line
    end

    # Skip progress and aux as they are covered by other status messages
    return '' if json['progress'] && json['status']
    return '' if json['aux']

    # Return error flag as a second result
    return [json['error'], true] if json['error']

    return json['stream'] if json['stream']

    if json['status']
      if json['id']
        return json['id'] + ': ' + json['status']
      else
        return json['status']
      end
    end

    return line # Nothing else matches
  end

  def self.puts(chunk)
    self.parse(chunk) do |text, is_error|
      if is_error
        $stdout.puts text.red
        raise text
      end
      $stdout.puts text unless text.empty?
    end
  end
end
