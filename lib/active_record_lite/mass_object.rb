class MassObject
  def self.my_attr_accessible(*args)
    @attributes ||= []
    @attributes.push(*args)
    my_attr_accessor(*args)
  end

  def self.attributes
    @attributes || []
  end

  def initialize(attrs)
    attrs.each do |k, v|
      k = k.to_sym unless k.is_a?(Symbol)
      raise "can't mass assign when #{k} is not on the whitelist" unless self.class.attributes.include?(k)
      instance_variable_set("@#{k}".to_sym, v)
    end
  end

  def get(atr)
    instance_variable_get("@#{atr}")
  end

  def self.parse_all(args)
    args.map { |hash| self.new(hash) }
  end
end

class Object
  def self.my_attr_accessor(*args)
    args.each do |attr_name|
      attr_name = attr_name.to_s
      instance_var_sym = "@#{attr_name}".to_sym
      define_method("#{attr_name}") do
        instance_variable_get(instance_var_sym)
      end

      define_method("#{attr_name}=") do |val|
        instance_variable_set(instance_var_sym, val)
      end
    end
  end
end