defmodule Fulib.FormableTest do
  use ExUnit.Case, async: true

  defmodule TestFulib.Testing.UserInfoUpdateForm do
    use Fulib.Formable,
      translator: Fulib.Translator,
      translator_prefix: "User Info"

    @required [:name]
    @cast_fields [:name, :age, :is_boy, :is_girl]

    schema do
      field(:name, :string)
      field(:title, :string, default: "untitled")
      field(:age, :integer)
      field(:is_boy, :boolean)
      field(:is_girl, :boolean)
    end

    def changeset(changeset, params) do
      changeset
      |> cast(params, @cast_fields, empty_values: [nil])
      |> validate_required(@required)
    end

    def submit(params \\ %{}, _resolution) do
      require IEx
      changeset = params |> from()

      changeset
      |> perform_action(:insert, fn changeset ->
        changeset
      end)
    end
  end

  alias TestFulib.Testing.UserInfoUpdateForm

  describe "message form" do
    test "get fields" do
      assert UserInfoUpdateForm.fields() == [:_id, :name, :title, :age, :is_boy, :is_girl]
    end

    test "translate" do
      form = UserInfoUpdateForm.submit(%{}, nil)
      form = UserInfoUpdateForm.translate(form)

      assert form.human_fields == %{
               _id: "User Info:_id",
               age: "User Info:age",
               is_boy: "User Info:is_boy",
               is_girl: "User Info:is_girl",
               name: "User Info:name",
               title: "User Info:title"
             }

      assert form.human_errors == [
               name: {"can't be blank", "can't be blank", [validation: :required]}
             ]
    end

    test "submit with wrong type" do
      form = %UserInfoUpdateForm{}

      changeset =
        UserInfoUpdateForm.changeset(form, %{
          name: "happy",
          age: "wrong type"
        })

      assert changeset.errors == [age: {"is invalid", [type: :integer, validation: :cast]}]
    end

    test "get_params" do
      form = %UserInfoUpdateForm{}

      changeset =
        UserInfoUpdateForm.changeset(form, %{
          name: "happy",
          is_girl: false
        })

      assert UserInfoUpdateForm.get_params(changeset, [:name, :age, :title, :is_boy, :is_girl]) ==
               %{
                 name: "happy",
                 is_girl: false,
                 title: "untitled"
               }
    end

    test "get_changes" do
      form = %UserInfoUpdateForm{}

      changeset =
        UserInfoUpdateForm.changeset(form, %{
          name: "happy",
          is_girl: false
        })

      assert changeset.changes == %{is_girl: false, name: "happy"}

      assert UserInfoUpdateForm.get_changes(changeset, [:name, :age, :title, :is_boy, :is_girl]) ==
               %{
                 name: "happy",
                 is_girl: false
               }

      assert UserInfoUpdateForm.get_changes(
               changeset,
               [:name, :age, :title, :is_boy, :is_girl],
               filter_false: false
             ) == %{
               name: "happy",
               is_girl: false
             }

      assert UserInfoUpdateForm.get_changes(
               changeset,
               [:name, :age, :title, :is_boy, :is_girl],
               compact: false
             ) == %{
               name: "happy",
               is_girl: false,
               is_boy: nil,
               age: nil,
               title: nil
             }
    end
  end
end
