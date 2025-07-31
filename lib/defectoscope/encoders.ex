defmodule Defectoscope.Encoders do
  @moduledoc false

  require Protocol

  Protocol.derive(Jason.Encoder, Plug.Upload, only: [:filename, :path, :content_type])

end
