defprotocol Fulib.Paginater do
  @doc """
  分页器

  ## pageable 可以分页的对象
  ## module   分页针对的module
  ## opts
  * page_style  :limit, :count, :all, :scroll
  * page
  * limit
  * offset
  """
  def paginate(pageable, module, opts)
end
