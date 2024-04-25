defmodule Kindling.Xml do
  def parse(doc) do
    case Saxy.SimpleForm.parse_string(doc) do
      {:ok, tree} ->
        process(tree)

      other ->
        other
    end
  end

  def process({resource_type, _, children}) do
    base = %{
      "resourceType" => resource_type
    }

    Enum.reduce(children, base, &reduce_child/2)
  end

  def reduce_child(binary, acc) when is_binary(binary), do: acc

  def reduce_child({"div", _subattrs, _children}, acc), do: acc

  def reduce_child({attribute_name, subattrs, children}, acc) do
    value =
      case subattrs do
        [{"value", value}] ->
          value

        list when is_list(list) ->
          attrs = Enum.into(list, %{})

          Enum.reduce(children, attrs, &reduce_child/2)
      end

    case Map.get(acc, attribute_name) do
      nil ->
        Map.put(acc, attribute_name, value)

      list when is_list(list) ->
        Map.put(acc, attribute_name, list ++ [value])

      other ->
        Map.put(acc, attribute_name, [other, value])
    end
  end
end
