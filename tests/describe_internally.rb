def describe_internally *args, &block
  example = describe *args, &block
  clazz = args[0]
  if clazz.is_a? Class
    saved_private_instance_methods = clazz.private_instance_methods
    example.before do
      clazz.class_eval { public *saved_private_instance_methods }
    end
    example.after do
      clazz.class_eval { private *saved_private_instance_methods }
    end
  end
end
