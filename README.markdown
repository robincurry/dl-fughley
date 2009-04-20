# DL-Fughley: Distribution List Fu - turn your models into email distribution lists.

Note - this project is still in its infacy and probably not quite ready for production use. Check back soon...

# Use named scopes, finders, or other methods as a distribution list

	class Person < ActiveRecord::Base
	  is_dl :all  	# results in a dl for all@yourdomain.com
	  is_dl :guys 	# results in a dl for guys@yourdomain.com
	  is_dl :girls 	# results in a dl for girls@yourdomain.com
	  is_dl :peeps 	# results in a dl for peeps@yourdomain.com
	  
	  named_scope :guys, :conditions => {:gender => 'M'}
	  named_scope :girls, :conditions => {:gender => 'F'}
	
	  def peeps
	    # return an enumerable containing your peeps
	  end
	end



# Or, use dl_missing to handle more complex scenarios

	class Person < ActiveRecord::Base
	  is_dl

	  def dl_missing(name)
		Group.find_by_name(name).people
	  end
	end



# Control who can send to the distribution list

	class Person < ActiveRecord::Base
	  is_dl :all, :allow => [:members]  # allow emails from anyone included in the distribution list.
	  is_dl :peeps, :allow => ['me@yourdomain.com', 'you@yourdomain.com', 'butnobodyelse@yourdomain.com']
	end



# Munge replies to send them back to the distribution list

	class Person < ActiveRecord::Base
	  is_dl :all, :reply_to => :list  # replies will be sent to all@yourdomain.com
	end



# Use a different from address for emails sent to distribution list

	class Person < ActiveRecord::Base
	  is_dl :all, :from => 'info@yourdomain.com'  # emails to group will come from info@yourdomain.com rather than original sender.
	end



# Add a subject prefix to all new emails to distribution list

	class Person < ActiveRecord::Base
	  is_dl :all, :subject_prefix => 'info'  # Will prefix subjects with "[info]"
	  is_dl :peeps, :subject_prefix => :list_name # Will prefix subjects with "[peeps]"
	end



# Copyright

Copyright (c) 2009 Robin Curry. See LICENSE for details.