class MyCoolExtension < Buildkite::Builder::Extension
  def build
    instance_eval(&execution_block)
  end
end

