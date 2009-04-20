require 'rubygems'

require 'test/unit'
require 'active_support'
require 'active_support/test_case'

require 'shoulda'
require 'shoulda/action_mailer'
require 'factory_girl'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'dl_fughley'


class Person < ActiveRecord::Base
  validates_presence_of :email, :message => "can't be blank"
end

class PostOffice < ActionMailer::Base
  
  def receive(email)
    Person.distribute(email)
  end
end


def connect(environment)
  conf = YAML::load(File.open(File.dirname(__FILE__) + '/database.yml'))
  ActiveRecord::Base.establish_connection(conf[environment])
end
connect('test')
load(File.dirname(__FILE__) + "/schema.rb")


# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
ActionMailer::Base.delivery_method = :test

class ActiveSupport::TestCase
  # fixtures :all
  
  def assert_deliveries(count)
    assert_equal count, ActionMailer::Base.deliveries.length
  end
end





