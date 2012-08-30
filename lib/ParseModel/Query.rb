module ParseModel
  module Model
    module ClassMethods
      QUERY_STUBS = [ :where, :first, :limit, :order, :eq, :notEq, :lt, :gt, :lte, :gte ] # :limit is different

      def method_missing(method, *args, &block)
        if method == :limit
          return self.limit(args.first) if args.length == 1
          return self.limit(args.first, args.last)
        elsif QUERY_STUBS.include? method.to_sym
          q = ParseModel::Query.new
          q.klass = self
          return q.send(method, args.first, &block) if block
          return q.send(method, args.first)
        elsif method.start_with?("find_by_")
          attribute = method.gsub("find_by_", "")
          cond[attribute] = args.first
          return self.limit(1).where(cond, block)
        elsif method.start_with?("find_all_by_")
          # attribute = method.gsub("find_all_by_", "")
          # cond[attribute] = args.first
          # return self.where(cond, block)
        else
        end
      end
    end
  end

  class Query
    attr_accessor :klass

    def initialize
      @conditions = @negativeConditions = @ltConditions = @gtConditions = @lteConditions = @gteConditions = {}
      @limit = @offset = nil
      @order = {}
    end

    def createQuery
      query = PFQuery.queryWithClassName(self.klass.to_s)
      
      @conditions.each do |key, value|
        query.whereKey(key, equalTo: value)
      end
      @negativeConditions.each do |key, value|
        query.whereKey(key, notEqualTo: value)
      end
      @ltConditions.each do |key, value|
        query.whereKey(key, lessThan: value)
      end
      @gtConditions.each do |key, value|
        query.whereKey(key, greaterThan: value)
      end
      @lteConditions.each do |key, value|
        query.whereKey(key, lessThanOrEqualTo: value)
      end
      @gteConditions.each do |key, value|
        query.whereKey(key, greaterThanOrEqualTo: value)
      end
      first = true
      @order.each do |field, direction|
        if first
          query.orderByAscending(field) if direction && direction == :asc
          query.orderByDescending(field) if direction && direction == :desc
          first = false
        else
          query.addAscendingOrder(field) if direction && direction == :asc
          query.addDescendingOrder(field) if direction && direction == :desc
        end
      end

      query.limit = @limit if @limit
      query.skip = @offset if @offset

      query
    end

    def showQuery
      $stderr.puts "Conditions: #{@conditions.to_s}"
      $stderr.puts "negativeConditions: #{@negativeConditions.to_s}"
      $stderr.puts "ltConditions: #{@ltConditions.to_s}"
      $stderr.puts "gtConditions: #{@gtConditions.to_s}"
      $stderr.puts "lteConditions: #{@lteConditions.to_s}"
      $stderr.puts "gteConditions: #{@gteConditions.to_s}"
      $stderr.puts "order: #{@order.to_s}"
      $stderr.puts "limit: #{@limit.to_s}"
      $stderr.puts "offset: #{@offset.to_s}"
    end

    def run(&callback)
      query = createQuery
      
      if @limit && @limit == 1
        fetchOne(query, &callback) 
      else
        fetchAll(query, &callback)
      end
      
      self
    end

    def fetchAll(query, &callback)
      myKlass = self.klass
      query.findObjectsInBackgroundWithBlock (lambda { |items, error|
        modelItems = items.map! { |item| myKlass.new(item) } if items
        callback.call modelItems, error
      })
    end

    def fetchOne(query, &callback)
      query.getFirstObjectInBackgroundWithBlock (lambda { |item, error|
        $stderr.puts "Fetched one!"
        modelItem = self.klass.new(item) if item
        callback.call modelItem, error
      })
    end

    # Query methods
    def where(*conditions, &callback)
      eq(conditions)
      run(&callback)
      nil
    end

    def all(&callback)
      run(&callback)
      nil
    end

    def first(&callback)
      limit(0, 1)
      run(&callback)
      nil
    end

    # Query parameter methods

    def limit(offset, number = nil)
      if number.nil?
        number = offset
        offset = 0
      end
      @offset = offset
      @limit = number
      self
    end

    def order(fields = {})
      fields.each do |field|
        @order.merge! field
      end
      self
    end

    def eq(*fields)
      fields.each do |field|
        @conditions.merge! field
      end
      self
    end

    def notEq(*fields)
      fields.each do |field|
        @negativeConditions.merge! field
      end
      self
    end

    def lt(*fields)
      fields.each do |field|
        @ltConditions.merge! field
      end
      self
    end

    def gt(*fields)
      fields.each do |field|
        @gtConditions.merge! field
      end
      self
    end

    def lte(*fields)
      fields.each do |field|
        @lteConditions.merge! field
      end
      self
    end

    def gte(*fields)
      fields.each do |field|
        @gteConditions.merge! field
      end
      self
    end

  end
end