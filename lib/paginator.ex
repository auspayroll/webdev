defmodule Paginator do
    @moduledoc """
    Paginate your Ecto queries.
  
    Instead of using: `Repo.all(query)`, you can use: `Paginator.page(query)`.
    To change the page you can pass the page number as the second argument.
  
    ## Examples
  
        iex> Paginator.paginate(query, 1)
        [%Item{id: 1}, %Item{id: 2}, %Item{id: 3}, %Item{id: 4}, %Item{id: 5}]
  
        iex> Paginator.paginate(query, 2)
        [%Item{id: 6}, %Item{id: 7}, %Item{id: 8}, %Item{id: 9}, %Item{id: 10}]
  
    """
  
    import Ecto.Query
  
    @results_per_page 10
  
    def paginate(repo, query, page) when is_nil(page) do
      paginate(repo, query, 1)
    end
  
    def paginate(repo, query, page) when is_binary(page) do
      paginate(repo, query, String.to_integer(page))
    end
  
    def paginate(repo, query, page) do
      results = execute_query(repo, query, page)
      total_results = count_total_results(repo, query)
      total_pages = count_total_pages(total_results)
  
      %{
        current_page: page,
        results_per_page: @results_per_page,
        total_pages: total_pages,
        total_results: total_results,
        list: results
      }
    end
  
    defp execute_query(repo, query, page) do
      query
      |> limit(^@results_per_page)
      |> offset((^page - 1) * ^@results_per_page)
      |> repo.all()
    end
  
    defp count_total_results(repo, query) do
      repo.aggregate(query, :count, :id)
    end
  
    defp count_total_pages(total_results) do
      total_pages = ceil(total_results / @results_per_page)
  
      if total_pages > 0, do: total_pages, else: 1
    end
  end


  defmodule Paginator.Helper do
    @moduledoc """
    Renders the pagination with a previous button, the pages, and the next button.
    """
  
    use Phoenix.HTML
  
    def render(conn, data, class: class) do
      first = prev_button(conn, data)
      pages = page_buttons(conn, data)
      last = next_button(conn, data)
  
      content_tag(:ul, [first, pages, last], class: class)
    end
  
    defp prev_button(conn, data) do
      page = data.current_page - 1
      disabled = data.current_page == 1
      params = build_params(conn, page)
  
      content_tag(:li, disabled: disabled) do
        link to: "?#{params}", rel: "prev" do
          "<"
        end
      end
    end
  
    defp page_buttons(conn, data) do
      for page <- 1..data.total_pages do
        class = if data.current_page == page, do: "active"
        disabled = data.current_page == page
        params = build_params(conn, page)
        content_tag(:li, class: class, disabled: disabled) do
          link(page, to: "?#{params}")
        end
      end
    end
  
    defp next_button(conn, data) do
      page = data.current_page + 1
      disabled = data.current_page >= data.total_pages
      params = build_params(conn, page)
      content_tag(:li, disabled: disabled) do
        link to: "?#{params}", rel: "next" do
          ">"
        end
      end
    end
  
    defp build_params(conn, page) do
      conn.query_params 
      |> Map.put("page", page) 
      |> URI.encode_query()
    end
  end