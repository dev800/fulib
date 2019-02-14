defmodule Fulib.ListTest do
  use ExUnit.Case

  describe "last" do
    test "ok" do
      assert Fulib.List.last([1, 2, 3, 4, 5]) == 5
      assert Fulib.List.last([1, 2, 3, 4, 5], 2) == [4, 5]
      assert Fulib.List.last([1, 2, 3, 4, 5], 0) == []
      assert Fulib.List.last([1, 2, 3, 4, 5], -2) == [1, 2]
      assert Fulib.List.last(nil, -2) == nil
      assert Fulib.List.last([], -2) == []
    end
  end

  describe "first" do
    test "ok" do
      assert Fulib.List.first([1, 2, 3, 4, 5]) == 1
      assert Fulib.List.first([1, 2, 3, 4, 5], 2) == [1, 2]
      assert Fulib.List.first([1, 2, 3, 4, 5], 0) == []
      assert Fulib.List.first([1, 2, 3, 4, 5], -2) == [4, 5]
      assert Fulib.List.first(nil, -2) == nil
      assert Fulib.List.first([], -2) == []
    end
  end
end
