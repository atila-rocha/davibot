defmodule DavibotTest do
  use ExUnit.Case
  doctest Davibot

  test "greets the world" do
    assert Davibot.hello() == :world
  end
end
