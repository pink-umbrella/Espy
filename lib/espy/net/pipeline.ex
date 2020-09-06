defmodule Espy.Net.Pipeline do

  defmacro __using__(_) do
    quote do
      import Espy.Net.Pipeline

      Module.register_attribute(__MODULE__, :pipes, accumulate: true)
      @on_definition Espy.Net.Pipeline
      @before_compile Espy.Net.Pipeline

      def init(opts \\ []) do
        @pipes
        |> Enum.reverse
        |> Enum.each(fn pipe -> apply(__MODULE__, :pipe_hook, [pipe, opts]) end)
      end

      def drain(ip, port, packet) do
        @pipes
        |> Enum.reduce(packet, fn pipe, pack -> apply(pipe, :drain, [ip, port, pack]) end)
      end

      def fill(ip, port, packet) do
        @pipes
        |> Enum.reverse
        |> Enum.reduce(packet, fn pipe, pack -> apply(pipe, :fill, [ip, port, pack]) end)
      end
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def pipes, do: @pipes
    end
  end

  def __on_definition__(env, kind, name, args, _guard, _body) do
    if kind == :defp
    and name == :pipe_hook
    and length(args) >= 1 do
      with [pipe_module | opts] <- args do
        Module.put_attribute(env.module, :pipes, {pipe_module, opts})
      end
    end
  end

  defmacro pipe(pipe_module, pipe_opts \\ []) do
    quote do
      defp pipe_hook(unquote(pipe_module), opts) do
        apply(unquote(pipe_module), :init, opts ++ unquote(pipe_opts))
      end
    end
  end


end
