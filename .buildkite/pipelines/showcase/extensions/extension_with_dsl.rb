class ExtensionWithDsl < Buildkite::Builder::Extension
  dsl do
    def component(name, &block)
      group("Component: #{name}", &block)
    end
  end
end

