defmodule Fulib.Model.Extends do
  # opts:
  #   repo_module
  defmacro __using__(opts \\ []) do
    quote do
      import Fulib.Model.Extends

      opts = unquote(opts)

      extends_module = opts[:extends_module] || __MODULE__

      Module.register_attribute(__MODULE__, :extends_module, accumulate: false)
      Module.put_attribute(__MODULE__, :extends_module, extends_module)

      repo_module = opts[:repo_module] || opts[:repo]

      Module.register_attribute(extends_module, :repo_module, accumulate: false)
      Module.put_attribute(extends_module, :repo_module, repo_module)

      target_module = opts |> Keyword.get(:target_module, extends_module)

      Module.register_attribute(extends_module, :target_module, accumulate: false)
      Module.put_attribute(extends_module, :target_module, target_module)

      # Begin lock_version_key ######################
      lock_version_key = opts[:lock_version_key] || :lock_version

      Module.register_attribute(extends_module, :lock_version_key, accumulate: false)
      Module.put_attribute(extends_module, :lock_version_key, lock_version_key)

      # Begin repo_primary_key ######################
      repo_primary_key = opts[:repo_primary_key] || :id

      Module.register_attribute(extends_module, :repo_primary_key, accumulate: false)
      Module.put_attribute(extends_module, :repo_primary_key, repo_primary_key)

      # Begin repo_primary_type ######################
      repo_primary_type = opts[:repo_primary_type] || :integer

      Module.register_attribute(extends_module, :repo_primary_type, accumulate: false)
      Module.put_attribute(extends_module, :repo_primary_type, repo_primary_type)

      # Begin polymorphic_mapping
      polymorphic_mapping = opts[:polymorphic_mapping] || %{}

      Module.register_attribute(extends_module, :polymorphic_mapping, accumulate: false)
      Module.put_attribute(extends_module, :polymorphic_mapping, polymorphic_mapping)

      # Begin uuid_default_length
      uuid_default_length = opts[:uuid_default_length] || 10

      Module.register_attribute(extends_module, :uuid_default_length, accumulate: false)
      Module.put_attribute(extends_module, :uuid_default_length, uuid_default_length)

      # Begin fields_rule
      fields_rule = (opts[:fields_rule] || %{}) |> Map.new()

      Module.register_attribute(extends_module, :fields_rule, accumulate: false)
      Module.put_attribute(extends_module, :fields_rule, fields_rule)

      Module.eval_quoted(
        @extends_module,
        quote do
          require Ecto.Query

          def fields_rule, do: @fields_rule

          def field_rule(field) do
            @fields_rule |> Fulib.get(field, %{})
          end

          def field_rule(field, rule_key) do
            field
            |> field_rule()
            |> Fulib.get(rule_key)
          end

          def validate_fields(changeset) do
            changeset |> validate_fields(@fields_rule)
          end

          def validate_fields(changeset, rules) do
            changeset |> Fulib.Validate.validate_changeset(rules)
          end

          @doc """
          生成uuid

          ## Params

          ### opts

          * `:format`
          * `:field`
          * `:length`
          """
          def generate_uuid(opts \\ []) do
            format = opts |> Fulib.get(:format, :dec)
            field = opts |> Fulib.get(:field, :uuid) |> Fulib.to_atom()
            length = opts |> Fulib.get(:length, @uuid_default_length) |> Fulib.to_i()
            uuid = _generate_uuid!(length, format)

            []
            |> Keyword.put(field, uuid)
            |> @extends_module.get_by()
            |> case do
              nil ->
                uuid

              _ ->
                generate_uuid(opts)
            end
          end

          defp _generate_uuid!(length, :hex) do
            Fulib.SecureRandom.hex((length / 2) |> Fulib.to_i())
          end

          defp _generate_uuid!(length, _) do
            :math.pow(10, length)
            |> Fulib.to_i()
            |> Kernel.-(1)
            |> :rand.uniform()
            |> Fulib.to_s()
            |> String.pad_trailing(length, "0")
          end

          def target_type_value do
            if value = @polymorphic_mapping |> get_in(["#{target_module()}", :value]) do
              value
            else
              raise "#{@extends_module} not config target_type_value"
            end
          end

          def target_type_key do
            if key = @polymorphic_mapping |> get_in(["#{target_module()}", :key]) do
              key
            else
              raise "#{@extends_module} not config target_type_key"
            end
          end

          def new do
            Code.eval_string("%#{@extends_module}{}") |> Tuple.to_list() |> hd
          end

          def change?(record, attrs) do
            record.__struct__.changeset(record, attrs).changes
            |> Map.drop([@lock_version_key])
            |> Fulib.present?()
          end

          def repo_module, do: @repo_module
          def repo, do: @repo_module
          def target_module, do: @target_module
          def repo_primary_type, do: @repo_primary_type
          def repo_primary_key, do: @repo_primary_key

          def paginate(), do: paginate(Ecto.Query.from(records in @extends_module))

          def paginate(query), do: paginate(query, [])

          @doc """
          对queryable进行分页

          ## query

          queryable

          ## opts

          * `:limit` 每页返回条数
          * `:page` 当前页面
          * `:offset` 偏移量（page_style=:limit适用）
          * `:page_style` 分页形式
            - `:count` 返回按照页数分页
            - `:scroll` 滚动查询
            - `:limit` 只返回对应的条目，不返回总页数
          """
          def paginate(query, opts) do
            Ecto.Query.from(records in query) |> Fulib.Paginater.paginate(@repo_module, opts)
          end

          @doc """
          根据ID查询
          """
          def get_id(nil), do: nil
          def get_id(id) when is_integer(id), do: id
          def get_id(record), do: Fulib.get(record, :id)

          @doc """
          获取两个model的差别
          """
          def model_diff(model_old, model_new, cast_fields \\ []) do
            model_old = model_old |> @repo_module.persisted!()
            model_new = model_new |> @repo_module.persisted!()

            Fulib.Map.diff(model_old, model_new, cast_fields)
          end

          def exclude(model), do: exclude(@extends_module, model)
          def exclude(queryable, nil), do: queryable

          def exclude(queryable, model) do
            Ecto.Query.from(
              records in queryable,
              where: field(records, ^repo_primary_key()) != ^Fulib.get(model, repo_primary_key())
            )
          end

          ######### Begin Find Each #################################################

          @default_find_each_batch_size 1_000

          def slave_find_each(callback_fn) when is_function(callback_fn) do
            slave_find_each(@default_find_each_batch_size, 0, callback_fn)
          end

          def slave_find_each(batch_size, callback_fn) when is_function(callback_fn) do
            slave_find_each(batch_size, 0, callback_fn)
          end

          def slave_find_each(batch_size, start, callback_fn) do
            queryable_find_each(@extends_module, batch_size, start, true, callback_fn)
          end

          def find_each(callback_fn) when is_function(callback_fn) do
            find_each(@default_find_each_batch_size, 0, callback_fn)
          end

          def find_each(batch_size, callback_fn) when is_function(callback_fn) do
            find_each(batch_size, 0, callback_fn)
          end

          def find_each(batch_size, start, callback_fn) do
            queryable_find_each(@extends_module, batch_size, start, false, callback_fn)
          end

          def queryable_find_each(queryable, callback_fn) when is_function(callback_fn) do
            queryable_find_each(queryable, @default_find_each_batch_size, 0, false, callback_fn)
          end

          def queryable_find_each(queryable, batch_size, callback_fn)
              when is_integer(batch_size) and is_function(callback_fn) do
            queryable_find_each(queryable, batch_size, 0, false, callback_fn)
          end

          def queryable_find_each(queryable, batch_size, start, callback_fn)
              when is_integer(batch_size) and is_integer(start) and is_function(callback_fn) do
            queryable_find_each(queryable, batch_size, start, false, callback_fn)
          end

          def queryable_find_each(queryable, batch_size, start, slave, callback_fn) do
            queryable =
              queryable
              |> Ecto.Query.exclude(:order_by)
              |> Ecto.Query.exclude(:limit)
              |> Ecto.Query.exclude(:offset)

            query =
              Ecto.Query.from(
                query in queryable,
                where: field(query, ^repo_primary_key()) > ^start,
                limit: ^batch_size,
                order_by: ^[asc: repo_primary_key()]
              )

            records =
              if slave do
                query |> repo_module().slave.all
              else
                query |> repo_module().all
              end

            records |> Enum.map(fn record -> callback_fn.(record) end)

            if last_record = records |> List.last() do
              queryable_find_each(
                queryable,
                batch_size,
                Fulib.get(last_record, repo_primary_key()),
                slave,
                callback_fn
              )
            end

            nil
          end

          ######### END Find Each #################################################

          def slave_find(primary_values, opts \\ []) do
            _find(@extends_module, primary_values, true, opts)
          end

          def slave_queryable_find(queryable, primary_values, opts \\ []) do
            _find(queryable, primary_values, true, opts)
          end

          def find(primary_values, opts \\ []) do
            _find(@extends_module, primary_values, false, opts)
          end

          def queryable_find(queryable, primary_values, opts \\ []) do
            _find(queryable, primary_values, false, opts)
          end

          defp _find(queryable, primary_values, slave, opts) when is_list(primary_values) do
            _get_list_by(queryable, repo_primary_key(), primary_values, slave, opts)
          end

          defp _find(queryable, primary_value, slave, opts) when is_boolean(slave) do
            if primary_value do
              clauses =
                Keyword.put(
                  [],
                  repo_primary_key(),
                  _normalize_primary_value(primary_value)
                )

              if slave do
                repo_module().slave.get_by(_query_one(queryable, opts), clauses)
              else
                repo_module().get_by(_query_one(queryable, opts), clauses)
              end
            end
          end

          defp _query_one(queryable, opts) do
            Ecto.Query.from(records in queryable, limit: ^1) |> _parse_query(opts)
          end

          defp _parse_query(queryable, opts) do
            if Fulib.present?(preload = opts[:preload]) do
              Ecto.Query.from(records in queryable, preload: ^preload)
            else
              queryable
            end
          end

          @array_where_types [:array, :enums_type]

          @doc """
          多功能where拼接

          ## Examples

          ```elixir
          iex> User.where(status: :published) # enum_type
          iex> User.where(status: [:published, :deleted])
          # enum_type可以传数组

          iex> User.where(status: {:array, [:published, :deleted]})
          # 可以传数组, 多值类型

          iex> User.where(status: {:enums_type, [:published, :deleted]})
          # enums_type可以传数组, 多值类型

          iex> User.where(status: {type, function, [:published, :deleted]})
          # type: 多值类型, 可传值：:array, :enums_type
          # function:
            可取值(
              :equal 等于
              :not_equal 不等于
              :less_than 小于
              :less_than_or_equal 小于等于
              :greater_then 大于
              :greater_than_or_equal 大于等于
              :contains 全包含
              :is_contained_by 被包含于
              :overlap 有其中一个
            )
          # 参见：https://www.postgresql.org/docs/9.4/functions-array.html
          ```
          """
          def where(binding) do
            @extends_module |> where(binding)
          end

          def where(queryable, binding) do
            Enum.reduce(binding, queryable, fn {k, v}, queryable ->
              _where(queryable, {k, v})
            end)
          end

          defp _where(queryable, {k, {type, v}}) when type in @array_where_types do
            _where(queryable, {k, {type, :equal, v}})
          end

          defp _where(queryable, {k, {type, :equal, v}}) when type in @array_where_types do
            Ecto.Query.from(records in queryable,
              where:
                fragment("? = ?", field(records, ^k), ^_get_array_value(queryable, k, type, v))
            )
          end

          defp _where(queryable, {k, {type, :not_equal, v}}) when type in @array_where_types do
            Ecto.Query.from(records in queryable,
              where:
                fragment("? <> ?", field(records, ^k), ^_get_array_value(queryable, k, type, v))
            )
          end

          defp _where(queryable, {k, {type, :less_than, v}}) when type in @array_where_types do
            Ecto.Query.from(records in queryable,
              where:
                fragment("? < ?", field(records, ^k), ^_get_array_value(queryable, k, type, v))
            )
          end

          defp _where(queryable, {k, {type, :less_than_or_equal, v}})
               when type in @array_where_types do
            Ecto.Query.from(records in queryable,
              where:
                fragment("? >= ?", field(records, ^k), ^_get_array_value(queryable, k, type, v))
            )
          end

          defp _where(queryable, {k, {type, :contains, v}}) when type in @array_where_types do
            Ecto.Query.from(records in queryable,
              where:
                fragment("? @> ?", field(records, ^k), ^_get_array_value(queryable, k, type, v))
            )
          end

          defp _where(queryable, {k, {type, :is_contained_by, v}})
               when type in @array_where_types do
            Ecto.Query.from(records in queryable,
              where:
                fragment("? @< ?", field(records, ^k), ^_get_array_value(queryable, k, type, v))
            )
          end

          defp _where(queryable, {k, {type, :overlap, v}}) when type in @array_where_types do
            Ecto.Query.from(records in queryable,
              where:
                fragment("? && ?", field(records, ^k), ^_get_array_value(queryable, k, type, v))
            )
          end

          defp _where(queryable, {k, {type, :greater_then, v}})
               when type in @array_where_types do
            Ecto.Query.from(records in queryable,
              where:
                fragment("? > ?", field(records, ^k), ^_get_array_value(queryable, k, type, v))
            )
          end

          defp _where(queryable, {k, {type, :greater_than_or_equal, v}})
               when type in @array_where_types do
            Ecto.Query.from(records in queryable,
              where:
                fragment("? >= ?", field(records, ^k), ^_get_array_value(queryable, k, type, v))
            )
          end

          defp _where(queryable, {k, v}) when is_list(v) do
            Ecto.Query.from(records in queryable, where: field(records, ^k) in ^v)
          end

          defp _where(queryable, {k, nil}) do
            Ecto.Query.from(records in queryable, where: is_nil(field(records, ^k)))
          end

          defp _where(queryable, {k, v}) do
            Ecto.Query.from(records in queryable, where: field(records, ^k) == ^v)
          end

          def where_not(binding) do
            @extends_module |> where_not(binding)
          end

          def where_not(queryable, binding) do
            Enum.reduce(binding, queryable, fn {k, v}, queryable ->
              _where_not(queryable, {k, v})
            end)
          end

          defp _where_not(queryable, {k, {type, v}}) do
            _where_not(queryable, {k, {type, :equal, v}})
          end

          # https://www.postgresql.org/docs/9.4/functions-array.html
          defp _where_not(queryable, {k, {type, :equal, v}}) when type in @array_where_types do
            Ecto.Query.from(records in queryable,
              where:
                fragment(
                  "not ? = ?",
                  field(records, ^k),
                  ^_get_array_value(queryable, k, type, v)
                )
            )
          end

          defp _where_not(queryable, {k, {type, :not_equal, v}})
               when type in @array_where_types do
            Ecto.Query.from(records in queryable,
              where:
                fragment(
                  "not ? <> ?",
                  field(records, ^k),
                  ^_get_array_value(queryable, k, type, v)
                )
            )
          end

          defp _where_not(queryable, {k, {type, :less_than, v}})
               when type in @array_where_types do
            Ecto.Query.from(records in queryable,
              where:
                fragment(
                  "not ? < ?",
                  field(records, ^k),
                  ^_get_array_value(queryable, k, type, v)
                )
            )
          end

          defp _where_not(queryable, {k, {type, :less_than_or_equal, v}})
               when type in @array_where_types do
            Ecto.Query.from(records in queryable,
              where:
                fragment(
                  "not ? >= ?",
                  field(records, ^k),
                  ^_get_array_value(queryable, k, type, v)
                )
            )
          end

          defp _where_not(queryable, {k, {type, :contains, v}}) when type in @array_where_types do
            Ecto.Query.from(records in queryable,
              where:
                fragment(
                  "not ? @> ?",
                  field(records, ^k),
                  ^_get_array_value(queryable, k, type, v)
                )
            )
          end

          defp _where_not(queryable, {k, {type, :is_contained_by, v}})
               when type in @array_where_types do
            Ecto.Query.from(records in queryable,
              where:
                fragment(
                  "not ? @< ?",
                  field(records, ^k),
                  ^_get_array_value(queryable, k, type, v)
                )
            )
          end

          defp _where_not(queryable, {k, {type, :overlap, v}}) when type in @array_where_types do
            Ecto.Query.from(records in queryable,
              where:
                fragment(
                  "not ? && ?",
                  field(records, ^k),
                  ^_get_array_value(queryable, k, type, v)
                )
            )
          end

          defp _where_not(queryable, {k, {type, :greater_then, v}})
               when type in @array_where_types do
            Ecto.Query.from(records in queryable,
              where:
                fragment(
                  "not ? > ?",
                  field(records, ^k),
                  ^_get_array_value(queryable, k, type, v)
                )
            )
          end

          defp _where_not(queryable, {k, {type, :greater_than_or_equal, v}})
               when type in @array_where_types do
            Ecto.Query.from(records in queryable,
              where:
                fragment(
                  "not ? >= ?",
                  field(records, ^k),
                  ^_get_array_value(queryable, k, type, v)
                )
            )
          end

          defp _where_not(queryable, {k, v}) when is_list(v) do
            Ecto.Query.from(records in queryable, where: field(records, ^k) not in ^v)
          end

          defp _where_not(queryable, {k, nil}) do
            Ecto.Query.from(records in queryable, where: not is_nil(field(records, ^k)))
          end

          defp _where_not(queryable, {k, v}) do
            Ecto.Query.from(records in queryable, where: field(records, ^k) != ^v)
          end

          def where_is_nil(keys) do
            @extends_module |> where_is_nil(keys)
          end

          def where_is_nil(queryable, keys) do
            keys
            |> Fulib.to_array()
            |> Enum.reduce(queryable, fn key, queryable ->
              Ecto.Query.from(records in queryable, where: is_nil(field(records, ^key)))
            end)
          end

          def where_is_not_nil(keys) do
            @extends_module |> where_is_not_nil(keys)
          end

          def where_is_not_nil(queryable, keys) do
            keys
            |> Fulib.to_array()
            |> Enum.reduce(queryable, fn key, queryable ->
              Ecto.Query.from(records in queryable, where: not is_nil(field(records, ^key)))
            end)
          end

          def where_lt(binding) do
            @extends_module |> where_lt(binding)
          end

          def where_lt(queryable, binding) do
            Enum.reduce(binding, queryable, fn {k, v}, queryable ->
              Ecto.Query.from(records in queryable, where: field(records, ^k) < ^v)
            end)
          end

          def where_gt(binding) do
            @extends_module |> where_gt(binding)
          end

          def where_gt(queryable, binding) do
            Enum.reduce(binding, queryable, fn {k, v}, binding ->
              Ecto.Query.from(records in queryable, where: field(records, ^k) > ^v)
            end)
          end

          def where_elt(binding) do
            @extends_module |> where_elt(binding)
          end

          def where_elt(queryable, binding) do
            Enum.reduce(binding, queryable, fn {k, v}, queryable ->
              Ecto.Query.from(records in queryable, where: field(records, ^k) <= ^v)
            end)
          end

          def where_egt(binding) do
            @extends_module |> where_egt(binding)
          end

          def where_egt(queryable, binding) do
            Enum.reduce(binding, queryable, fn {k, v}, queryable ->
              Ecto.Query.from(records in queryable, where: field(records, ^k) >= ^v)
            end)
          end

          def or_where(binding) do
            @extends_module |> or_where(binding)
          end

          def or_where(queryable, binding) do
            Enum.reduce(binding, queryable, fn {k, v}, queryable ->
              cond do
                is_list(v) ->
                  Ecto.Query.from(records in queryable, or_where: field(records, ^k) in ^v)

                is_nil(v) ->
                  Ecto.Query.from(records in queryable, or_where: is_nil(field(records, ^k)))

                true ->
                  Ecto.Query.from(records in queryable, or_where: field(records, ^k) == ^v)
              end
            end)
          end

          def preload(binding), do: @extends_module |> preload(binding)

          def preload(queryable, binding) do
            if Fulib.present?(binding) do
              queryable |> Ecto.Query.preload(^binding)
            else
              queryable
            end
          end

          def perform_preload_entries(record, inner_opts, opts \\ [])

          def perform_preload_entries(nil, inner_opts, opts), do: nil

          def perform_preload_entries([], inner_opts, opts), do: []

          @doc """
          预加载相应的数组关联数据

          ## Params

          ### records

          预加载的记录

          ### opts

          * `:primary_value_collect_fn` 收集主键值的方法
          * `:query_handle_fn` 处理query的方法
          """
          def perform_preload_entries(records, inner_opts, opts) when is_list(records) do
            %{
              entries_key: entries_key,
              entries_module: entries_module,
              primary_field_key: primary_field_key,
              foreign_field_key: foreign_field_key
            } = inner_opts |> Map.new()

            primary_value_collect_fn =
              opts[:primary_value_collect_fn] ||
                fn record ->
                  record |> Fulib.get(primary_field_key) |> Fulib.to_array()
                end

            query_handle_fn = opts[:query_handle_fn] || fn query -> query end

            primary_values =
              records
              |> Enum.reduce([], fn record, values ->
                primary_value_collect_fn.(record) ++ values
              end)
              |> Fulib.compact()
              |> Enum.uniq()

            entries_index =
              entries_module
              |> query_handle_fn.()
              |> queryable_find(primary_values)
              |> Enum.map(fn entry ->
                if primary_value = entry |> Fulib.get(foreign_field_key) do
                  {primary_value, entry}
                end
              end)
              |> Fulib.compact()
              |> Map.new()

            Enum.map(records, fn record ->
              entries =
                record
                |> primary_value_collect_fn.()
                |> Enum.map(fn primary_value ->
                  entries_index |> Fulib.get(primary_value)
                end)
                |> Fulib.compact()

              record |> Map.put(entries_key, entries)
            end)
          end

          def perform_preload_entries(
                %Fulib.Paginater.CountResult{entries: records} = paginater,
                inner_opts,
                opts
              ) do
            %Fulib.Paginater.CountResult{
              paginater
              | entries:
                  perform_preload_entries(
                    records,
                    inner_opts,
                    opts
                  )
            }
          end

          def perform_preload_entries(
                %Fulib.Paginater.LimitResult{entries: records} = paginater,
                inner_opts,
                opts
              ) do
            %Fulib.Paginater.LimitResult{
              paginater
              | entries:
                  perform_preload_entries(
                    records,
                    inner_opts,
                    opts
                  )
            }
          end

          def perform_preload_entries(
                %Fulib.Paginater.ScrollResult{entries: records} = paginater,
                inner_opts,
                opts
              ) do
            %Fulib.Paginater.ScrollResult{
              paginater
              | entries:
                  perform_preload_entries(
                    records,
                    inner_opts,
                    opts
                  )
            }
          end

          def perform_preload_entries(
                %Fulib.Paginater.AllResult{entries: records} = paginater,
                inner_opts,
                opts
              ) do
            %Fulib.Paginater.AllResult{
              paginater
              | entries:
                  perform_preload_entries(
                    records,
                    inner_opts,
                    opts
                  )
            }
          end

          def perform_preload_entries(record, inner_opts, opts) do
            record
            |> Fulib.to_array()
            |> perform_preload_entries(inner_opts, opts)
            |> List.first()
          end

          def select(binding), do: @extends_module |> select(binding)

          def select(queryable, binding) do
            queryable |> Ecto.Query.select(^binding)
          end

          def select_merge(binding), do: @extends_module |> select_merge(binding)

          def select_merge(queryable, binding) do
            queryable |> Ecto.Query.select_merge(^binding)
          end

          def order_by(binding) do
            @extends_module |> order_by(binding)
          end

          def order_by(queryable, binding) do
            if Fulib.present?(binding) do
              Ecto.Query.from(record in queryable, order_by: ^binding)
            else
              queryable
            end
          end

          def limit(binding) do
            @extends_module |> limit(binding)
          end

          def limit(queryable, binding) do
            queryable |> Ecto.Query.limit(^binding)
          end

          def touch!(nil), do: nil

          def touch!(record) do
            record
            |> record.__struct__.changeset(%{inserted_at: Timex.now()})
            |> repo_module().update!
          end

          def get_list_by(primary_key, values) do
            get_list_by(@extends_module, primary_key, values)
          end

          def get_list_by(queryable, primary_key, values) do
            _get_list_by(queryable, primary_key, values)
          end

          defp _get_list_by(queryable, primary_key, values \\ [], slave \\ false, opts \\ []) do
            values =
              (values || [])
              |> Fulib.to_array()
              |> Fulib.compact()
              |> Enum.uniq()

            if Fulib.present?(values) do
              query =
                Ecto.Query.from(
                  records in queryable,
                  where: field(records, ^primary_key) in ^values,
                  select: records
                )

              query = query |> _parse_query(opts)

              records =
                if slave do
                  repo_module().slave.all(query)
                else
                  repo_module().all(query)
                end

              Enum.sort(records, fn a, b ->
                Fulib.get_index(values, Fulib.get(a, primary_key)) <
                  Fulib.get_index(values, Fulib.get(b, primary_key))
              end)
            else
              []
            end
          end

          def get_by(clauses \\ [], opts \\ []) do
            @extends_module |> queryable_get_by(clauses, opts)
          end

          def queryable_get_by(queryable, clauses \\ [], opts \\ []) do
            repo_module().get_by(_query_one(queryable, opts), clauses, opts)
          end

          def get_by!(clauses \\ [], opts \\ []) do
            @extends_module |> queryable_get_by!(clauses, opts)
          end

          def queryable_get_by!(queryable, clauses \\ [], opts \\ []) do
            repo_module().get_by!(_query_one(queryable, opts), clauses, opts)
          end

          def slave_get_by(clauses \\ [], opts \\ []) do
            @extends_module |> slave_queryable_get_by(clauses, opts)
          end

          def slave_queryable_get_by(queryable, clauses \\ [], opts \\ []) do
            repo_module().slave().get_by(_query_one(queryable, opts), clauses, opts)
          end

          def slave_get_by!(clauses \\ [], opts \\ []) do
            @extends_module |> slave_queryable_get_by!(clauses, opts)
          end

          def slave_queryable_get_by!(queryable, clauses \\ [], opts \\ []) do
            repo_module().slave().get_by!(_query_one(queryable, opts), clauses, opts)
          end

          def last, do: last(@extends_module, [])

          def last(args) do
            cond do
              args == @extends_module -> last(args, [])
              Fulib.get(args, :__struct__) == Ecto.Query -> last(args, [])
              true -> last(@extends_module, args)
            end
          end

          def last(queryable, opts) do
            limit = opts |> Fulib.get(:limit, nil)
            order_by = opts |> Fulib.get(:order_by)
            slave = opts |> Fulib.get(:slave)
            repo_module = if slave, do: repo_module(), else: repo_module().slave()

            if limit do
              Ecto.Query.last(queryable, order_by) |> Ecto.Query.limit(^limit) |> repo_module.all
            else
              Ecto.Query.last(queryable, order_by) |> repo_module.one
            end
          end

          def first, do: first(@extends_module, [])

          def first(args) do
            cond do
              args == @extends_module -> first(args, [])
              Fulib.get(args, :__struct__) == Ecto.Query -> first(args, [])
              true -> first(@extends_module, args)
            end
          end

          def first(queryable, opts) do
            limit = opts |> Fulib.get(:limit, nil)
            order_by = opts |> Fulib.get(:order_by)
            slave = opts |> Fulib.get(:slave)
            repo_module = if slave, do: repo_module(), else: repo_module().slave()

            if limit do
              Ecto.Query.first(queryable, order_by) |> Ecto.Query.limit(^limit) |> repo_module.all
            else
              Ecto.Query.first(queryable, order_by) |> repo_module.one
            end
          end

          def exists? do
            Ecto.Query.from(records in @extends_module) |> exists?()
          end

          def exists?(queryable) do
            not (queryable |> first |> is_nil)
          end

          def one do
            Ecto.Query.from(records in @extends_module) |> one()
          end

          def one(queryable) do
            queryable |> repo_module().one
          end

          def all do
            Ecto.Query.from(records in @extends_module) |> all()
          end

          def all(queryable) do
            queryable |> repo_module().all
          end

          def none do
            Ecto.Query.from(records in @extends_module) |> none()
          end

          def none(queryable) do
            queryable |> where(Keyword.new([{@repo_primary_key, nil}]))
          end

          def all_where(binding) do
            @extends_module |> all_where(binding)
          end

          def all_where(queryable, binding) do
            queryable |> where(binding) |> repo_module().all
          end

          def all_where_not(binding) do
            @extends_module |> all_where_not(binding)
          end

          def all_where_not(queryable, binding) do
            queryable |> where_not(binding) |> repo_module().all
          end

          def count() do
            Ecto.Query.from(records in @extends_module) |> count()
          end

          def count(queryable) do
            primary_key =
              queryable.from
              |> case do
                {_table_name, module} ->
                  module

                %{source: {_table_name, module}} ->
                  module
              end
              |> apply(:__schema__, [:primary_key])
              |> hd

            queryable
            |> Ecto.Query.exclude(:order_by)
            |> Ecto.Query.exclude(:preload)
            |> Ecto.Query.exclude(:select)
            |> Ecto.Query.exclude(:group_by)
            |> Ecto.Query.select([m], count(field(m, ^primary_key), :distinct))
            |> repo_module().one
          end

          defp _normalize_primary_value(primary_value) do
            case repo_primary_type() do
              :integer -> Fulib.to_i(primary_value)
              :string -> Fulib.to_s(primary_value)
              _ -> primary_value
            end
          end

          def insert!(attrs) when is_list(attrs), do: insert!(Map.new(attrs))

          def insert!(attrs) when is_map(attrs) do
            struct(@extends_module)
            |> @extends_module.changeset(attrs)
            |> @extends_module.repo().insert!
          end

          def insert(attrs) when is_list(attrs), do: insert(Map.new(attrs))

          def insert(attrs) when is_map(attrs) do
            struct(@extends_module)
            |> @extends_module.changeset(attrs)
            |> @extends_module.repo().insert
          end

          def insert_or_update!(attrs) when is_list(attrs), do: insert_or_update!(Map.new(attrs))

          def insert_or_update!(attrs) when is_map(attrs) do
            struct(@extends_module)
            |> @extends_module.changeset(attrs)
            |> @extends_module.repo().insert_or_update!
          end

          def insert_or_update(attrs) when is_list(attrs), do: insert_or_update(Map.new(attrs))

          def insert_or_update(attrs) when is_map(attrs) do
            struct(@extends_module)
            |> @extends_module.changeset(attrs)
            |> @extends_module.repo().insert_or_update
          end

          def insert!(attrs) when is_list(attrs), do: insert!(Map.new(attrs))

          def insert!(attrs) when is_map(attrs) do
            struct(@extends_module)
            |> @extends_module.changeset(attrs)
            |> @extends_module.repo().insert!
          end

          @doc """
          更新
          """
          def update!(old, attrs) when is_list(attrs), do: update!(old, Map.new(attrs))

          def update!(old, attrs) do
            old
            |> @extends_module.changeset(attrs)
            |> @extends_module.repo().update!
          end

          def update(attrs) when is_map(attrs) do
            attrs
            |> Fulib.get(@repo_primary_key)
            |> update(attrs)
          end

          def update(nil, _attrs), do: {:error, "#{@repo_primary_key} can't nil"}

          def update(primary_value, attrs)
              when is_integer(primary_value) or is_binary(primary_value) do
            update(__MODULE__.find(primary_value), attrs)
          end

          def update(old, attrs) when is_list(attrs), do: update(old, Map.new(attrs))

          def update(old, attrs) do
            old
            |> __MODULE__.changeset(attrs)
            |> __MODULE__.repo().update
          end

          def with_undeleted() do
            Ecto.Query.from(records in @extends_module) |> with_undeleted()
          end

          def with_undeleted(query) do
            Fulib.Ecto.SoftDelete.Query.with_undeleted(query)
          end

          def with_deleted() do
            Ecto.Query.from(records in @extends_module) |> with_deleted()
          end

          def with_deleted(query) do
            Fulib.Ecto.SoftDelete.Query.with_deleted(query)
          end

          defp _get_array_value(query, k, :enums_type, v) do
            @extends_module.__changeset__()[k].dump(v)
            |> case do
              {:ok, values} ->
                values

              _ ->
                raise Ecto.QueryError, message: "#{inspect(v)} can't dump", query: query
            end
          end

          defp _get_array_value(_query, _k, _type, v), do: Fulib.to_array(v)
        end
      )
    end
  end
end
