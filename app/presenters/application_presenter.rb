class ApplicationPresenter
  def self.collection(records, **opts)
    records.map { |r| new(r, **opts).as_json }
  end
end
