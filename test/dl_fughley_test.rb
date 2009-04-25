require 'test_helper'

class DlFughleyTest < ActiveSupport::TestCase
  context "receive email" do
    setup do
      @people = []
      1.upto(5) do |i|
        @people[i - 1] = Factory(:person)
      end
      
      # Establish that the person class is a dl
      Person.is_dl
      
      # Reset deliveries during setup. Otherwise they will accumulate after each test.
      ActionMailer::Base.deliveries = []
    end
    
    context "addressed to yall@mydomain.com (a non-existent group)" do
      setup do
        email = to_email(
        :from => 'user@example.com', 
        :to => 'yall@mydomain.com', 
        :subject => 'test to the whole group', 
        :body => 'Hello Entire Group!')
        PostOffice.receive(email.to_s)
      end

      should "not trigger delivery to anybody" do
        assert_deliveries 0
      end
    end

    context "addressed to [some group name]@mydomain.com" do
      setup do
        # add a leaders distribution list to the Person class that only returns 2 people.
        Person.instance_eval do
          def dl_leaders
            [Factory(:person), Factory(:person)]
          end
        end

        email = to_email(
        :from => 'user@example.com', 
        :to => 'leaders@example.com', 
        :subject => 'test to a group', 
        :body => 'Hello Leaders!')
        PostOffice.receive(email.to_s)
      end
    
      should "trigger delivery to each person in the group" do
        assert_deliveries 2
      end
    end
    
    context "addressed to [some other group]@mydomain.com" do
      setup do
        # add a holla distribution list to the Person class that only returns 3 people.
        Person.instance_eval do
          def dl_holla
            [Factory(:person), Factory(:person), Factory(:person)]
          end
        end
        
        email = to_email(
        :from => 'user@example.com', 
        :to => 'holla@example.com', 
        :subject => 'test to the group', 
        :body => 'Holla!')
        PostOffice.receive(email.to_s)
      end
      
      should "trigger delivery to each person in the group" do
       assert_deliveries 3
      end
    end
    
    context "addressed to all@mydomain.com (a named scope)" do
      setup do
        # Tell the person class that Person.all is a dl.
        Person.is_dl(:all)
        
        email = to_email(
        :from => 'user@example.com', 
        :to => 'all@example.com', 
        :subject => 'test to the whole group', 
        :body => 'Hello everybody!')
        PostOffice.receive(email.to_s)
      end
      
      should "trigger delivery to each person" do
       assert_deliveries Person.count
      end
    end
    
    context "addressed to yousguys@mydomain.com (a group handled by dl_missing)" do
      setup do
        Person.instance_eval do
          def dl_missing(name, *args)
            if name.to_s =~ /^yousguys$/ then
              [Factory(:person), Factory(:person), Factory(:person)]
            end
          end
        end
        
        email = to_email(
        :from => 'user@example.com', 
        :to => 'yousguys@example.com', 
        :subject => 'test to a missing group', 
        :body => 'Hello everybody!')
        PostOffice.receive(email.to_s)
      end
      
      should "trigger delivery to each person in the group" do
       assert_deliveries 3
      end
    end
  
  end
  
  context "dl setup" do
    context "duplicate lists" do
      setup do
        Person.is_dl(:all)
        Person.is_dl(:all)
      end

      should "not fail. it should only create one dl_all method" do
        assert true
      end
    end
    
    context ":as option" do
      setup do 
        Person.is_dl(:all, :as => :everyone)
      end
      
      
      should "result in a dl that uses the named_scope but with the provided :as name" do
        assert Person.respond_to?(:dl_everyone)
      end
    end
    
    context ":email_field option" do
      setup do
        Person.class_eval do
          def email_addy
            "alternate_email@yourdomain.com"
          end
        end
        
        1.upto(2) do |i|
          Factory(:person)
        end
        
        Person.is_dl(:all, :email_field => :email_addy)
        
        email = to_email(
        :from => 'user@example.com', 
        :to => 'all@example.com', 
        :subject => 'test to the whole group', 
        :body => 'Hello everybody!')
        PostOffice.receive(email.to_s)
      end
      
      should "use the provided field for email address" do
        assert_sent_email do |email|
          email.to.include?('alternate_email@yourdomain.com')
        end
      end
    end
    
    context ":allow option with whitelist (:allow => ['allowed_user_1@example.com', 'allowed_user_2@example.com'])" do
      setup do
        1.upto(2) do |i|
          Factory(:person)
        end
        
        Person.is_dl(:all, :allow => ['allowed_user_1@example.com', 'allowed_user_2@example.com'])
        
        # Reset deliveries during setup. Otherwise they will accumulate after each test.
        ActionMailer::Base.deliveries = []
      end
      
      should "not allow a user not in whitelist to send email" do
        email = to_email(
        :from => 'spammer@example.com', 
        :to => 'all@example.com', 
        :subject => 'test to the whole group', 
        :body => 'Hello everybody!')
        PostOffice.receive(email.to_s)
        
        assert_deliveries 0
      end
      
      should "allow a user in the whitelist to send email" do
        email = to_email(
        :from => 'allowed_user_2@example.com', 
        :to => 'all@example.com', 
        :subject => 'test to the whole group', 
        :body => 'Hello everybody!')
        PostOffice.receive(email.to_s)
        
        assert_deliveries Person.count
      end
    end
    
    context ":allow option with :members option (:allow => [:members])" do
      setup do
        Factory(:person, :email => "allowed_user_1@example.com")
        Factory(:person, :email => "allowed_user_2@example.com")
        
        Person.is_dl(:all, :allow => [:members])
        
        # Reset deliveries during setup. Otherwise they will accumulate after each test.
        ActionMailer::Base.deliveries = []
      end
      
      should "not allow a user not a member of group to send email" do
        email = to_email(
        :from => 'spammer@example.com', 
        :to => 'all@example.com', 
        :subject => 'test to the whole group', 
        :body => 'Hello everybody!')
        PostOffice.receive(email.to_s)
        
        assert_deliveries 0
      end
      
      should "allow a user in the group to send email" do
        email = to_email(
        :from => 'allowed_user_1@example.com', 
        :to => 'all@example.com', 
        :subject => 'test to the whole group', 
        :body => 'Hello everybody!')
        PostOffice.receive(email.to_s)
        
        assert_deliveries Person.count
      end
    end
    
    context ":from option" do
      setup do
        Factory(:person)
        Person.is_dl(:all, :from => "info@example.com")
        
        # Reset deliveries during setup. Otherwise they will accumulate after each test.
        ActionMailer::Base.deliveries = []
        
        email = to_email(
        :from => 'user@example.com', 
        :to => 'all@example.com', 
        :subject => 'test to the whole group', 
        :body => 'Hello everybody!')
        PostOffice.receive(email.to_s)
      end
      
      should "use provided :from address in place of the origin email from address" do
        assert_sent_email do |email|
          email.from.include?('info@example.com')
        end
      end
    end
    
    context ":reply_to option is :sender (:reply_to => :sender)" do
      setup do
        Factory(:person)
        Person.is_dl(:all, :reply_to => :sender)
        
        # Reset deliveries during setup. Otherwise they will accumulate after each test.
        ActionMailer::Base.deliveries = []
        
        @email = to_email(
        :from => 'user@example.com', 
        :to => 'all@example.com', 
        :subject => 'test to the whole group', 
        :body => 'Hello everybody!')
        PostOffice.receive(@email.to_s)
      end
      
      should "send emails with reply-to header set to sender's address" do
        assert_sent_email do |email|
          email.reply_to == @email.from
        end
      end
    end
    
    context ":reply_to option is :list (:reply_to => :list)" do
      setup do
        Factory(:person)
        Person.is_dl(:all, :reply_to => :list)
        
        # Reset deliveries during setup. Otherwise they will accumulate after each test.
        ActionMailer::Base.deliveries = []
        
        @email = to_email(
        :from => 'user@example.com', 
        :to => 'all@example.com', 
        :subject => 'test to the whole group', 
        :body => 'Hello everybody!')
        PostOffice.receive(@email.to_s)
      end
      
      should "send emails with reply-to header set to list address" do
        assert_sent_email do |email|
          email.reply_to == @email.to
        end
      end
    end
    
    context ":subject_prefix => :list_name" do
      setup do
        Factory(:person)
        Person.is_dl(:all, :subject_prefix => :list_name)
        
        # Reset deliveries during setup. Otherwise they will accumulate after each test.
        ActionMailer::Base.deliveries = []
        
        @email = to_email(
        :from => 'user@example.com', 
        :to => 'all@example.com', 
        :subject => 'test to the whole group', 
        :body => 'Hello everybody!')
        PostOffice.receive(@email.to_s)
      end
      
      should "send emails with a subject prefix matching the downcased list name" do
        assert_sent_email do |email|
          email.subject =~ /\[all\]/
        end
      end
    end
    
    context ":subject_prefix => 'all-my-peeps'" do
      setup do
        Factory(:person)
        Person.is_dl(:all, :subject_prefix => "all-my-peeps")
        
        # Reset deliveries during setup. Otherwise they will accumulate after each test.
        ActionMailer::Base.deliveries = []
        
        @email = to_email(
        :from => 'user@example.com', 
        :to => 'all@example.com', 
        :subject => 'test to the whole group', 
        :body => 'Hello everybody!')
        PostOffice.receive(@email.to_s)
      end
      
      should "send emails with a subject prefix matching the downcased list name" do
        assert_sent_email do |email|
          email.subject =~ /\[all-my-peeps\]/
        end
      end
    end
    
    context ":subject_prefix => false" do
      setup do
        Factory(:person)
        Person.is_dl(:all, :subject_prefix => false)
        
        # Reset deliveries during setup. Otherwise they will accumulate after each test.
        ActionMailer::Base.deliveries = []
        
        @email = to_email(
        :from => 'user@example.com', 
        :to => 'all@example.com', 
        :subject => 'test to the whole group', 
        :body => 'Hello everybody!')
        PostOffice.receive(@email.to_s)
      end
      
      should "send emails without a subject prefix" do
        assert_sent_email do |email|
          !(email.subject =~ /\[all\]/)
        end
      end
    end
    
    context ":subject_prefix => nil" do
      setup do
        Factory(:person)
        Person.is_dl(:all, :subject_prefix => nil)
        
        # Reset deliveries during setup. Otherwise they will accumulate after each test.
        ActionMailer::Base.deliveries = []
        
        @email = to_email(
        :from => 'user@example.com', 
        :to => 'all@example.com', 
        :subject => 'test to the whole group', 
        :body => 'Hello everybody!')
        PostOffice.receive(@email.to_s)
      end
      
      should "send emails without a subject prefix" do
        assert_sent_email do |email|
          !(email.subject =~ /\[all\]/)
        end
      end
    end
    
    context ":subject_prefix => :list_name, but prefix is already included (in a reply, for instance)" do
      setup do
        Factory(:person)
        Person.is_dl(:all, :subject_prefix => :list_name)
        
        # Reset deliveries during setup. Otherwise they will accumulate after each test.
        ActionMailer::Base.deliveries = []
        
        @email = to_email(
        :from => 'user@example.com', 
        :to => 'all@example.com', 
        :subject => 'RE: [all] test to the whole group', 
        :body => 'Hello everybody!')
        PostOffice.receive(@email.to_s)
      end
      
      should "not have multiple prefixes in the subject" do
        assert_sent_email do |email|
          !(email.subject =~ /\[all\].*\[all\]/)
        end
      end
    end
    
    context ":subject_prefix => 'all-my-peeps', but prefix is already included (in a reply, for instance)" do
      setup do
        Factory(:person)
        Person.is_dl(:all, :subject_prefix => "all-my-peeps")
        
        # Reset deliveries during setup. Otherwise they will accumulate after each test.
        ActionMailer::Base.deliveries = []
        
        @email = to_email(
        :from => 'user@example.com', 
        :to => 'all@example.com', 
        :subject => 're: [all-my-peeps] test to the whole group', 
        :body => 'Hello everybody!')
        PostOffice.receive(@email.to_s)
      end
      
      should "send emails with a subject prefix matching the downcased list name" do
        assert_sent_email do |email|
          !(email.subject =~ /\[all-my-peeps\].*\[all-my-peeps\]/)
        end
      end
    end
  end
  
  context "distribute" do
    setup do
      Factory(:person)
      Person.is_dl(:all)

      # Reset deliveries during setup. Otherwise they will accumulate after each test.
      ActionMailer::Base.deliveries = []

      @email = to_email(
      :from => 'user@example.com', 
      :to => 'all@example.com', 
      :subject => 're: [all-my-peeps] test to the whole group', 
      :body => 'Hello everybody!')
    end

    context "default" do
      setup do
        Person.distribute(@email)
      end

      should "send email via ActionMailer to each member of dl" do
        assert_deliveries Person.count
      end
    end

    context "with block" do
      setup do
        @count = 0
        Person.distribute(@email) {|person, email| @count = @count+1 }
      end
      
      should "yield each person and email to the block" do
        assert @count == Person.count
      end
    
      should "not send via ActionMailer (unless called by block)" do
        assert_deliveries 0
      end
    end
  end
  

  
  private
    def to_email(values)
      values.symbolize_keys!
      email = TMail::Mail.new
      email.to = values[:to]
      email.from = values[:from]
      email.subject = values[:subject]
      email.body = values[:body]
      email
    end
end
