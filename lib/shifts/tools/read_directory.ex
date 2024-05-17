defmodule Shifts.Tools.ReadDirectory do
  use Shifts.Tool

  description "A tool to recursively list the contents of a directory. Returns a list of files contained in the directory."
  param :directory, :string, "Path of the directory to read"

  #@impl true
  def call(%{directory: directory}) do
    file_list =
      walk_dir(directory)
      |> Enum.map(& "- #{&1}")
      |> Enum.join("\n")

    "File paths:\n#{file_list}"
  end

  # Recursively walks the directory and lists files
  defp walk_dir(directory) do
    directory
    |> File.ls!()
    |> Enum.flat_map(fn filename ->
      full_path = Path.join(directory, filename)
      case File.stat(full_path) do
        {:ok, %{type: :directory}} -> walk_dir(full_path)
        {:ok, %{type: :regular}} -> [full_path]
        _ -> []
      end
    end)
  end

end
