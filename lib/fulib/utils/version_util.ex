defmodule Fulib.VersionUtil do
  def compare(version1, version2) do
    try do
      Version.compare(_normalize(version1), _normalize(version2))
    catch
      _, _ -> :invalid
    end
  end

  defp _normalize(version) do
    version
    |> Fulib.to_s()
    |> String.split(".")
    |> case do
      [x, y, z] ->
        [x, y, z] |> Enum.join(".")

      [x, y, z | tail] ->
        Enum.join([x, y, z], ".") <> Enum.join(tail, "-")

      other ->
        other
    end
  end
end
