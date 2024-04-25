defmodule Kindling.Client.Req do
  def get(request, opts \\ []) do
    Req.get(request, opts)
  end

  def post(request, opts \\ []) do
    Req.post(request, opts)
  end

  def put(request, opts \\ []) do
    Req.put(request, opts)
  end

  def delete(request, opts \\ []) do
    Req.delete(request, opts)
  end
end
