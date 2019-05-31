defmodule Fulib.WechatUtil do
  @doc """
  微信的解码工具

  https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/signature.html

  参考自：https://github.com/rubencaro/cipher/blob/master/lib/cipher.ex
  """
  def decrypt(key, iv, encrypted_data) do
    key = Base.decode64!(key)
    iv = Base.decode64!(iv)

    encrypted_data
    |> Base.decode64()
    |> case do
      {:ok, encrypted_data} ->
        :aes_cbc128
        |> :crypto.block_decrypt(key, iv, encrypted_data)
        |> Fulib.Cipher.depad()
        |> Jason.decode()

      :error ->
        {:error, :encrypted_data_invalid}
    end
  end
end
