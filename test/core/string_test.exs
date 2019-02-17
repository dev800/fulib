defmodule Fulib.StringTest do
  use ExUnit.Case

  describe "liquid_render" do
    test "ok" do
      template = """
      {% if user.visible %}
        Nick Name: {{ user.nickName }}
      {% else %}
        User Invisible
      {% endif %}
      """

      assert Fulib.String.liquid_render!(template, %{user: %{visible: true, nickName: "Happy"}}) ==
               "\n  Nick Name: Happy\n\n"

      assert Fulib.String.liquid_render!(template, %{user: %{visible: false, nickName: "Happy"}}) ==
               "\n  User Invisible\n\n"
    end
  end
end
