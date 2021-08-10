Buildkite::Builder.template do |context|
  label "Step w/ Arg: #{context[:foo]}"
  command 'true'
end
