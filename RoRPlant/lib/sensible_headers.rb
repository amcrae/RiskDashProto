# frozen_string_literal: true

module SensibleHeaders
  
  def reconstruct_headers(env)
    env
      .select { |k, _v| k.start_with? 'HTTP_' }
      .transform_keys { |k| k.sub(/^HTTP_/, '').split('_').map(&:capitalize).join('-') }
      .sort.to_h
      .tap do |headers|
        headers.define_singleton_method :[] do |k|
          super(k.split(/[-_]/).map(&:capitalize).join('-'))
        end
      end
  end
  
end
