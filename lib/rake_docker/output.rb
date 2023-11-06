# frozen_string_literal: true

require 'json'
require 'colored2'

module RakeDocker
  module Output
    def self.parse(chunk)
      chunk.each_line do |line|
        yield parse_line(line)
      end
    end

    def self.parse_line(line)
      json, error = try_parse_json(line)
      return to_unparseable(line) if error

      return to_skipped(json) if line_skippable?(json)
      return to_error(json) if line_includes_error?(json)
      return to_stream(json) if line_includes_stream?(json)
      return to_status_with_id(json) if line_includes_status_and_id?(json)
      return to_status(json) if line_includes_status?(json)

      to_fallthrough(line)
    end

    def self.try_parse_json(line)
      [JSON.parse(line.strip), false]
    rescue JSON::ParserError
      [nil, true]
    end

    def self.print(chunk)
      parse(chunk) do |text, error|
        if error
          $stdout.print "#{text.red}\n"
          raise text
        end
        $stdout.print text unless text.empty?
      end
    end

    def self.line_includes_id?(json)
      json['id']
    end

    def self.line_includes_status?(json)
      json['status']
    end

    def self.line_includes_progress?(json)
      json['progress']
    end

    def self.line_includes_aux?(json)
      json['aux']
    end

    def self.line_includes_error?(json)
      json['error']
    end

    def self.line_includes_stream?(json)
      json['stream']
    end

    def self.line_includes_status_and_id?(json)
      line_includes_status?(json) &&
        line_includes_id?(json)
    end

    def self.line_skippable?(json)
      (line_includes_status?(json) &&
        line_includes_progress?(json)) ||
        line_includes_aux?(json)
    end

    def self.to_unparseable(line)
      [line, false]
    end

    def self.to_skipped(_)
      ['', false]
    end

    def self.to_status_with_id(json)
      ["#{json['id']}: #{json['status']}\n", false]
    end

    def self.to_status(json)
      ["#{json['status']}\n", false]
    end

    def self.to_stream(json)
      [json['stream'], false]
    end

    def self.to_error(json)
      [json['error'], true]
    end

    def self.to_fallthrough(line)
      [line, false]
    end
  end
end
