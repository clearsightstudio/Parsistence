module Parsistence
  module User
    include ::Parsistence::Model

    attr_accessor :PFUser
    
    RESERVED_KEYS = [:objectId, :username, :password, :email]

    def initialize(pf=nil)
      if pf
        self.PFObject = pf
      else
        self.PFObject = PFObject.objectWithClassName(self.class.to_s)
      end

      self
    end
    
    def PFObject=(value)
      @PFObject = value
      @PFUser = @PFObject
    end
    
    def PFUser=(value)
      self.PFObject = value
    end

    module ClassMethods    
      def all
        query = PFQuery.queryForUser
        users = query.findObjects
        users
      end
      
      def currentUser
        PFUser.currentUser
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
