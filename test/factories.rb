Factory.sequence :email do |n|
  "somebody#{n}@example.com"
end

Factory.define :person do |person|
  person.email { Factory.next(:email) }
end