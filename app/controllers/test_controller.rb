class TestController < ApplicationController
  layout "inertia"

  def reactivity
    render inertia: "Test/Reactivity", props: {
      page: { title: "Svelte Reactivity Test", bodyClass: "sidebar" }
    }
  end
end
  end
end
