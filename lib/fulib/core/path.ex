defmodule Fulib.Path do
  # 递归获取子目录
  def find_dirs(root_dir, callback_fn) do
    find_dirs(root_dir, root_dir, callback_fn)
  end

  def find_dirs(root_dir, current_dir, callback_fn) do
    case current_dir |> File.ls() do
      {:ok, child_names} ->
        child_names
        |> Enum.sort()
        |> Enum.map(fn child_name ->
          file_path = current_dir |> Path.join(child_name)

          cond do
            # 如果是一个目录
            File.dir?(file_path) ->
              callback_fn.(%{
                root_dir: root_dir,
                current_dir: file_path
              })

              find_dirs(root_dir, file_path, callback_fn)

            true ->
              nil
          end
        end)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def find_files_of_dir(root_dir, callback_fn) do
    find_files_of_dir(root_dir, root_dir, callback_fn)
  end

  def find_files_of_dir(root_dir, current_dir, callback_fn) do
    case current_dir |> File.ls() do
      {:ok, file_names} ->
        file_names
        |> Enum.sort()
        |> Enum.map(fn file_name ->
          file_path = current_dir |> Path.join(file_name)

          cond do
            File.dir?(file_path) ->
              find_files_of_dir(root_dir, file_path, callback_fn)

            true ->
              callback_fn.(%{
                root_dir: root_dir,
                current_dir: current_dir,
                file_path: file_path,
                file_name: file_name
              })
          end
        end)

      {:error, reason} ->
        {:error, reason}
    end
  end
end
