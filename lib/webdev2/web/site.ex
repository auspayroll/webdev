defmodule Webdev2.Web.Site do
  use Ecto.Schema
  import Ecto.Changeset
  alias AuthMe.UserManager.User
  alias Webdev2.Ecto.Types.TSVectorType
  require IEx
  

  @re_stylesheet_tag ~r/<link (?=[^>]*rel=["']stylesheet["'])(?=[^>]*href=["'](\S+)["']).*?>/i
  @re_href ~r/\shref=["'](.*?)["']/i
  @re_src ~r/\ssrc=["'](.*?)["']/i
  @re_domain ~r/^https?:\/\/.*/i
  @excluded_tags ["script", "svg", "iframe", "form", "object", "canvas", "applet", "embed", "video", "audio", "input", "footer"]
  @base64_data ~r/data:.*?base64\s*,\s*[A-Za-z0-9+\/=]+/si

  defmodule Response do
    defstruct status_code: -1, headers: [], body: ""
  end

  schema "sites" do
    field :body, :string
    field :tags, :string
    field :title, :string
    field :url, :string
    field :description, :string
    field :search_vector, TSVectorType
    belongs_to :user, User
    field :ranking, :float, virtual: true
    timestamps()
  end

  @doc false
  def changeset(site, attrs) do
    site
    |> cast(attrs, [:tags, :title, :url, :body, :description])
    |> validate_required([:url])
    |> valid_string?([:body])
  end

  def apply_default(changeset, field) do
    body = Map.get(changeset.changes, :body) || changeset.data.body
    if :title in Map.keys(changeset.changes) && !Map.get(changeset.changes, field) || !changeset.data.id do 
      Ecto.Changeset.put_change(changeset, field, html_title(body))
    else
      changeset 
    end
  end

  def apply_defaults(site_changeset) do
    site_changeset = if site_changeset.valid? && site_changeset.changes do 
      site_changeset
      |> apply_default(:title)
      |> apply_default(:description)
    else 
      site_changeset
    end
  end

  def meta_tags(html) do
    case first_tag(html, "head") do
      [ match | _captures ] -> 
        meta_tags = Regex.scan(~r/<meta\b.*?\/?>/i, match)
        IO.inspect meta_tags
        case meta_tags do 
          nil -> []
          _ -> 
            for [capture | _options] <- meta_tags do
              Regex.named_captures(~r/<meta\b(?=.*\bname="(?<name>.*?)".*?>)?(?=.*\bcharset="(?<charset>.*?)".*?>)?(?=.*\bcontent="(?<content>.*?)".*?>)?.*?>/i, capture)
            end
        end
      nil -> []
    end
  end

  def meta_tag(html, tag) do
    metas = meta_tags(html)
    Enum.find(metas, fn %{"name" => name } -> name == tag end)
  end

  def html_tag(html) do
    Regex.named_captures(~r/<(?<name>\w+)\b(?<options>.*?)>(?<content>.*?)<\/\w+>/i, html)
  end

  def first_tag(html, tag) do
    {:ok, re } = Regex.compile("<" <> tag <> "\\b(.*?)>(.*?)<\/" <> tag <> ">", "si")
    Regex.run(re, html)
  end

  def html_tags(html, tag) do
    {:ok, re } = Regex.compile("<" <> tag <> "\\b(.*?)>(.*?)<\/" <> tag <> ">", "si")
    result = Regex.scan(re, html)
    if result == [] do #try <tag/> form
      {:ok, re } = Regex.compile("<" <> tag <> "\\b(.*?)()\/?>", "si")
      Regex.scan(re, html)
    else
      result
    end
  end

  def html_title(body) do
    case first_tag(body, "title") do
      [_tag_match, _options, content] -> content
      _ -> case first_tag(body, "h1") do
        [_tag_match, _options, content] -> content
        _ -> case first_tag(body, "h2") do
          [_tag_match, _options, content] -> content
          _ -> case first_tag(body, "h3") do
            [_tag_match, _options, content] -> content
            _ -> ""
          end
        end
      end
    end
  end

  def html_description(body) do
    match = meta_tag(body, "description")
    case match do
      %{ "content" =>  content  } -> content
      nil -> nil
    end
  end

  def html_replace(html, tag, replace_with \\ "") do
    {:ok, re } = Regex.compile("<" <> tag <> "\\b(.*?)>(.*?)<\/" <> tag <> ">", "i")
    Regex.replace(re, html, replace_with)
  end

  def insert_style(body, []) do
    body
  end

  def css_url_import(css, []) do
    css
  end

  def css_url_import(css, matches) do
    [[line, url] | rest] = matches
    case http_fetch_site(url) do
      {:ok, %Response{ status_code: 200, body: body }} ->
        body = "/* imported from " <> url <> " */ " <> body 
        css = String.replace(css, line, body)
        css_url_import(css, rest)
      other_response -> css_url_import(css, rest)
    end
  end

  def css_url_imports(css) do
    matches = Regex.scan(~r/@import\s*url\(\s*['"]?\s*(.*?)[^'"]?\)/, css)
    css_url_import(css, matches)
  end

  def insert_style(body, replacements) do
    [replacement| tail ] = replacements
    case replacement do
      { tag, css_content, url } -> 
        css_content = css_content
        |> insert_full_links_css(url)
        |> css_url_imports
        css_content = "<!--- " <> url <> " --->" <> "<style>" <> css_content <> "</style>"
        insert_style(String.replace(body, tag, css_content), tail)

      { tag, nil, _ } -> insert_style(body, tail)
    end
  end

  def fetch_style([tag, link]) do
    url = HtmlEntities.decode(link)
    case http_fetch_site(url) do
      {:ok, response } -> 
        { tag, response.body, url }
      _ -> { tag, "", url }
    end
  end

  def stylesheets(body) do
    Regex.scan(@re_stylesheet_tag, body)
  end

  def css_urls(body) do
    Regex.scan(~r/@import\s*url\(\s*['"]?\s*(.*?)[^'"]?\)/, body)
  end

  def insert_styles(body) do
    replacements = stylesheets(body)
    tasks = for replacement <- replacements do
      Task.async(fn -> fetch_style(replacement) end)
    end
    replacements = Task.yield_many(tasks, 10000) # 10 seconds
    |> Enum.map(fn { task, {:ok, result } } -> result  end)
    insert_style(body, replacements) # replacements [{ tag, response.body, url }]
  end

  def domain_part(url) do
    [result | _rest] = Regex.run(~r/^https?:\/\/(?:[^@?&\s\/]+)/i, url)
    result
  end

  def full_link(link, url) do
    link = if Regex.match?(@re_domain, link) do
      link
    else 
      URI.merge(url, link) |> to_string
    end
  end

  def insert_link(body, []) do
    body
  end

  def insert_link(body, links) do
    [[tag, new_tag] | tail ] = links
    insert_link(String.replace(body, tag, new_tag), tail)
  end


  def insert_full_links(body, base_url, pattern) do
    matches = Regex.scan(pattern, body) 
    links = for [tag, link] <- matches do
      new_link = full_link(link, base_url)
      new_tag = String.replace(tag, link, new_link)
      [tag, new_tag]
    end
    insert_link(body, links)
  end 

  def insert_full_links(body, base_url) do
    body 
    |> insert_full_links(base_url, @re_src)
    |> insert_full_links(base_url, @re_href)
  end 

  def insert_full_links_css(body, base_url) do
    insert_full_links(body, base_url, ~r/url\(\s*['"]?\s*(.*?)[^'"]?\)/) 
    #match url("http://....") pattern
  end

  def reload_site(site_changeset) do
    if site_changeset.valid? && site_changeset.changes != %{} do 
      url = Map.get(site_changeset.changes, :url) || site_changeset.data.url
      case fetch_web_site(url) do
        {:ok, %Response{ status_code: 200, body: body }} -> 
          Ecto.Changeset.put_change(site_changeset, :body, body)
        {:warning, _} ->    
         Ecto.Changeset.put_change(site_changeset, :body, "")
        {:error, reason } -> 
          IO.inspect reason
          site_changeset
          Ecto.Changeset.put_change(site_changeset, :body, "")
      end
    else 
      site_changeset
    end
  end

  def remove_control_chars(body) do
    body
    |> String.replace("\n", "")
    |> String.replace("\t", "")
  end

  def http_fetch_site(url) do
    if url do
      IO.puts "http_fetch_site " <> url
      case HTTPoison.get(url) do
        {:ok, %HTTPoison.Response{ status_code: status_code, headers: headers, body: body }} ->
          case status_code do
            200 -> 
              IO.puts "response OK"
              if String.valid? body do 
                { :ok,  %Response{status_code: 200, headers: headers, body: body} }
              else 
                IO.puts "invalid utf string: status code " <> to_string(200)
                { :ok,  %Response{status_code: status_code, headers: headers, body: ""} }
              end
            _ -> 
              IO.puts "invalid response: status code " <> to_string(status_code)
              { :warning,  %Response{status_code: status_code, headers: headers, body: ""} }
          end
        {:error, reason } ->
          IO.inspect reason
          {:error, Kernel.inspect(reason) }
      end
    else 
      {:error, "empty url", status_code: -1, headers: [], }
    end
  end

  def remove_tag(body, []) do
    body
  end

  def remove_tag(body, [match|rest]) do
    body = String.replace(body, match, "")
    remove_tag(body, rest)
  end

  def remove_match(body, re) do
    Regex.replace(re, body, "")
  end

  def remove_tags(body, []) do
    body
  end

  def remove_tags(body, [tag|rest]) do
    matches = html_tags(body, tag)
    |> Enum.map(fn [full_tag|_rest] -> full_tag end)
    body = remove_tag(body, matches)
    remove_tags(body, rest)
  end

  def enable_noscript(body, []) do
    body
  end

  def enable_noscript(body, [[noscript, _options, content] | rest]) do
    body = String.replace(body, noscript, content)
    enable_noscript(body, rest)
  end

  def enable_noscript(body) do
    noscripts = html_tags(body, "noscript")
    enable_noscript(body, noscripts)
  end

  def fetch_web_site(url) do
    case http_fetch_site(url) do
    {:ok, %Response{ status_code: 200, body: body }} -> 
      body = body 
      |> remove_tags(@excluded_tags)
      |> insert_full_links(url)
      |> insert_styles
      |> remove_control_chars
      |> remove_match(@base64_data)
      |> enable_noscript
      {:ok, %Response{ status_code: 200, body: body }}

    other_response -> other_response
 
    end
  end

  def fetch_site(site \\ %{}) do
    case http_fetch_site(site["url"]) do
      {:ok, %Response{ status_code: status_code, headers: headers, body: body }} -> 
        %{ body: body, status_code: status_code, headers: headers, 
            url: site["url"], title: site["title"], tags: site["tags"] }
      {:error, reason } -> 
        %{ body: reason, status_code: -1, url: site["url"], title: site["title"], tags: site["tags"] }
    end
  end

  defp valid_body?(%Ecto.Changeset{changes: %{body: body}} = changeset) do 
    if String.length(body) > 0 && !String.valid?(body) do
      add_error(changeset, :body, "invalid string")
    else 
      changeset
    end
  end

  def paragraphs(nil) do
    []
  end

  def paragraphs(body \\ "") do
    tags = html_tags(body, "p")
    for [_html, _options, content] <- tags, do: content 
  end

  defp valid_body?(changeset), do: changeset

  def valid_string?(changeset, fields) do 
    case fields do
      [] -> changeset
      [field|rest] -> 
        val = changeset.changes[field]
        changeset = if !is_nil(val) && String.length(val) > 0 && !String.valid?(val) do
          add_error(changeset, field, "invalid string")
        else 
          changeset
        end
        valid_string?(changeset, rest)
    end
  end

  defp get_body(changeset), do: changeset

end


defmodule Util do
  def valid_utf8?(<<_::utf8, rest::binary>>), do: valid_utf8?(rest)
  def valid_utf8?(<<>>), do: true
  def valid_utf8?(_), do: false

  def test do
    for binary <- [<<0>>, <<239, 191, 191>>, <<128>>] do
      IO.inspect {binary, String.valid?(binary), Util.valid_utf8?(binary)}
    end
  end
end


