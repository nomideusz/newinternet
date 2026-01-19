class SearchesController < ApplicationController
  layout "inertia"

  before_action :set_messages

  def index
    @query = query if query.present?
    @recent_searches = Current.user.searches.ordered
    @return_to_room = last_room_visited

    render inertia: "Searches/Index", props: {
      page: { title: "Search", bodyClass: "sidebar searches" },
      query: @query,
      recentSearches: SearchPresenter.collection(@recent_searches),
      returnToRoomPath: @return_to_room ? room_path(@return_to_room) : nil,
      results: MessagePresenter.collection(@messages, view: :search_result)
    }
  end

  def create
    Current.user.searches.record(query)
    redirect_to searches_url(q: query)
  end

  def clear
    Current.user.searches.destroy_all
    redirect_to searches_url
  end

  private
    def set_messages
      if query.present?
        @messages = Current.user.reachable_messages.search(query).last(100)
      else
        @messages = Message.none
      end
    end

    def query
      params[:q]&.gsub(/[^[:word:]]/, " ")
    end
end
