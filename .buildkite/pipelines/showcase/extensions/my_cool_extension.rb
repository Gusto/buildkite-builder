require 'cool_lib'

class MyCoolExtension < Buildkite::Builder::Extension
  def build
    CoolLib.resolve(log)

    pipeline do
      command do
        label 'Appended Step'
        command 'echo 1'
      end
    end
  end
end

