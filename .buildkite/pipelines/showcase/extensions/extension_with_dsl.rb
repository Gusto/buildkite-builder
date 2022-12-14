class ExtensionWithDsl < Buildkite::Builder::Extension
  dsl do
    def component(name, &block)
      group do
        label "Component: #{name}"
        yield
      end
    end
  end
end

