defmodule Shifts.Job.Helpers do
  alias Shifts.{Chore, Job}

  @spec exec(Job.t(), list(Job.chore_name())) :: Job.t()
  def exec(%Job{} = job, names) when is_list(names) do
    Enum.reduce(names, job, & exec(&2, &1))
  end

  @spec exec(Job.t(), Job.chore_name()) :: Job.t()
  def exec(%Job{shift: shift} = job, name) do
    with {:ok, chore_init} <- apply(shift.mod, :handle_chore, [name, job]) do
      chore = case chore_init do
        task when is_binary(task) -> Chore.new(task: task)
        opts when is_list(opts) -> Chore.new(opts)
        %Chore{} = chore -> chore
      end

      chat = Chore.exec(chore)
      Job.push_to_cell(job, {:exec, name, chat})
    end
  end

end
