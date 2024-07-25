defmodule SequinTest do
  use ExUnit.Case
  doctest Sequin

  test "greets the world" do
    assert Sequin.hello() == :world
  end
end
