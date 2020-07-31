defmodule EspyTest do
  use ExUnit.Case
  doctest Espy

  test "greets the world" do
    assert Espy.hello() == :world
  end
end
