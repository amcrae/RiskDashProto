# require "test_helper"
require_relative '../test_helper'

class SystemGraphTest < ActiveSupport::TestCase

    def test_load_dependencies()
        g = SystemGraph.load_dependencies_graph("1-2b01-2")
        puts "g is #{g}"
        assert g != nil
        assert g.nodes != nil
        assert g.nodes.size() == 9
        
    end

end
