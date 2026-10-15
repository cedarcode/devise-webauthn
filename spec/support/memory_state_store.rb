# frozen_string_literal: true

class MemoryStateStore
  def self.challenges
    @challenges ||= {}
  end

  def self.reset
    challenges.clear
  end

  def initialize(_request); end

  def write(purpose, challenge)
    self.class.challenges[purpose] = challenge
  end

  def pending?(purpose)
    self.class.challenges.key?(purpose)
  end

  def consume(purpose)
    self.class.challenges.delete(purpose)
  end

  def issue_two_factor_token(_jti); end

  def two_factor_token_issued?(_jti)
    true
  end

  def consume_two_factor_token(jti)
    jti
  end
end
