ActiveRecord::Schema.define(:version => 0) do

  create_table "people", :force => true do |t|
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
end