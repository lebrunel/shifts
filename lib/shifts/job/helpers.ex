defmodule Shifts.Job.Helpers do
  alias Shifts.{Chat, ChatResult, Chore, Job}

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

  @spec get_all(Job.t()) :: list(ChatResult.t())
  def get_all(%Job{} = job) do
    Keyword.values(Job.get_state(job))
  end

  @spec get_all(Job.t(), Job.chore_name()) :: list(ChatResult.t())
  def get_all(%Job{} = job, name) do
    Keyword.get_values(Job.get_state(job), name)
  end

  @spec get_first(Job.t()) :: ChatResult.t()
  def get_first(%Job{} = job) do
    get_all(job) |> hd()
  end

  @spec get_first(Job.t(), Job.chore_name()) :: ChatResult.t()
  def get_first(%Job{} = job, name) do
    Keyword.get(Job.get_state(job), name)
  end

  @spec get_last(Job.t()) :: Chat.t()
  def get_last(%Job{} = job) do
    Enum.reverse(get_all(job)) |> hd()
  end

  @spec get_last(Job.t(), Job.chore_name()) :: ChatResult.t()
  def get_last(%Job{} = job, name) do
    Keyword.get(Enum.reverse(Job.get_state(job)), name)
  end

end
