class ExtensionWithTemplate < Buildkite::Builder::Extension
  template(:default) do |context|
    label('Generated from an extension template')
    command('echo "From extension template :default"')
    env(TEMPLATE_VAR: 'VALUE')
  end

  template(:baz) do |context|
    label('Generated from an extension template')
    command('echo "From extension template :baz"')
    env(TEMPLATE_VAR: 'VALUE')
  end
end
