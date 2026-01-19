class SearchPresenter < ApplicationPresenter
  def initialize(search)
    @search = search
  end

  def as_json
    {
      id: @search.id,
      user_id: @search.user_id,
      query: @search.query,
      created_at: @search.created_at
    }
  end
end
