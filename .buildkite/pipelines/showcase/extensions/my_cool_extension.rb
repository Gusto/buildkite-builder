class MyCoolExtension < Buildkite::Builder::Extension
  def build
    instance_eval(&options_block)
  end
end

