defmodule Shifts.Tools.ReadFile do
  use Shifts.Tool

  description "A tool to read the contents of a file. Opens a file by its path and returns the contents."
  param :file_path, :string, "Full file path of the file to read"

  @impl true
  def call(%{file_path: file_path}) do
    File.read!(file_path)
  end

end
