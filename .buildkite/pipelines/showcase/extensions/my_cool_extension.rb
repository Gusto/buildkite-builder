class MyCoolExtension < Buildkite::Builder::Extension
  def build
    instance_eval(&option_block)
  end
end

