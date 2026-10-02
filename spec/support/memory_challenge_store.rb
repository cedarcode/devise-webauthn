# frozen_string_literal: true

class MemoryChallengeStore
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

  def pending?(purpose, _credential)
    self.class.challenges.key?(purpose)
  end

  def consume(purpose, _credential)
    self.class.challenges.delete(purpose)
  end
end
