defmodule KindlingTest do
  use ExUnit.Case
  doctest Kindling

  test "greets the world" do
    assert Kindling.hello() == :world
  end
end
