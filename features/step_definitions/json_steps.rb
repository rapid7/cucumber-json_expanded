Then /^it should (pass|fail) with JSON:$/ do |pass_fail, json|
  actual = normalise_json(MultiJson.load(all_stdout))
  expected = MultiJson.load(json)
  
  # require 'pry'
  # binding.pry
  
  expect(actual).to be_matching expected
  assert_success(pass_fail == 'pass')
end