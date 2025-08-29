# frozen_string_literal: true

module GeneratorHelper
  def invoke(generator)
    capture(:stdout) do
      generator.invoke_all
    end
  end
end
