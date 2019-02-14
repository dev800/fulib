defmodule Fulib.String.Yaml.Decoder do
  @yamerl_options [
    detailed_constr: true,
    str_node_as_binary: true
  ]

  def read_all_from_file(path, options \\ []) do
    path
    |> :yamerl_constr.file(@yamerl_options)
    |> Fulib.String.Yaml.Mapper.process(options)
  end

  def read_from_file(path, options \\ []) do
    path
    |> :yamerl_constr.file(@yamerl_options)
    |> List.last()
    |> Fulib.String.Yaml.Mapper.process(options)
  end

  def read_all_from_string(string, options \\ []) do
    string
    |> :yamerl_constr.string(@yamerl_options)
    |> Fulib.String.Yaml.Mapper.process(options)
  end

  def read_from_string(string, options \\ []) do
    string
    |> :yamerl_constr.string(@yamerl_options)
    |> List.last()
    |> Fulib.String.Yaml.Mapper.process(options)
  end
end
