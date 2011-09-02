require 'tsort'
require_relative 'project'

class Array
  include TSort
  alias tsort_each_node each

  def tsort_each_child(node, &block)
    if node.is_a?(Project)
      node.dependencies.each(&block)
    else
      node.each(&block) if node
    end
  end

  def psort
    tsort.select{|p| include? p }
  end
end