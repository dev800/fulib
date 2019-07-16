defmodule Fulib.ValueTest do
  use ExUnit.Case

  describe "convert_to" do
    test "ok" do
      assert Fulib.Value.convert_to("hello,world\t,\nnice", :csl) == ["hello", "world", "nice"]
    end
  end
end
