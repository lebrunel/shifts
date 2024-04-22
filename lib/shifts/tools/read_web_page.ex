defmodule Shifts.Tools.ReadWebPage do
  use Shifts.Tool

  description "A tool to read the contents of a web page. Scrapes a URL and returns the HTML web page as readable plain text"
  param :url, :string, "URL of the web page to scrape"

  @impl true
  def call(_shift, %{url: url}) do
    with  %{status: status} = res when status in 200..299 <- Req.get!(url) do
      if Readability.is_response_markup(res.headers) do
        html_tree = Readability.Helper.normalize(res.body, url: url)
        article_tree = Readability.ArticleBuilder.build(html_tree, page_url: url)
        title = Readability.title(html_tree)
        body = Readability.readable_text(article_tree)

        "# #{title}\n\n#{body}"
      else
        res.body
      end
    else
      %{status: status} -> "HTTPError: status code #{status}"
    end
  end

end
