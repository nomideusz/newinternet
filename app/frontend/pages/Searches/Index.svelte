<script>
  import { router } from "@inertiajs/svelte";
  import SearchResultItem from "../../components/SearchResultItem.svelte";

  import iconBroom from "images/broom.svg";
  import iconSearch from "images/search.svg";
  import iconArrowLeft from "images/arrow-left.svg";
  import iconRemove from "images/remove.svg";
  import iconArrowUp from "images/arrow-up.svg";

  let {
    page,
    query = "",
    recentSearches = [],
    returnToRoomPath = "/",
    results = [],
  } = $props();

  let searchQuery = $state("");

  // Sync searchQuery with query prop when it changes
  $effect(() => {
    searchQuery = query;
  });

  function clearSearch() {
    searchQuery = "";
    router.get("/searches");
  }

  function clearRecentSearches() {
    if (confirm("Are you sure you want to clear your recent searches?")) {
      router.delete("/searches/clear");
    }
  }

  function handleSubmit(event) {
    event.preventDefault();
    if (searchQuery.trim()) {
      router.get("/searches", { q: searchQuery.trim() });
    }
  }

  function focusContent(node) {
    node.focus();
  }
</script>

<!-- Nav content: Query pill and recent searches -->
<div class="searches__nav">
  {#if query}
    <div class="searches__query flex align-center gap pad-block-start-half">
      <div class="btn btn--reversed btn--faux align-center gap txt-nowrap">
        <span class="overflow-ellipsis">"{query}"</span>
        <span class="flex-item-no-shrink">{results.length}</span>
      </div>
    </div>
  {/if}

  <div
    class="searches__recents align-center gap pad-block-half overflow-y overflow-hide-scrollbar"
  >
    {#each recentSearches as search}
      <a
        href="/searches?q={encodeURIComponent(search.query)}"
        class="align-center gap room btn txt-nowrap"
      >
        <span class="overflow-ellipsis">"{search.query}"</span>
      </a>
    {/each}

    {#if recentSearches.length > 0}
      <button
        type="button"
        class="btn searches__btn"
        onclick={clearRecentSearches}
      >
        <img src={iconBroom} aria-hidden="true" alt="" />
        <span class="for-screen-reader">Clear recent searches</span>
      </button>
    {/if}
  </div>
</div>

<!-- Sidebar content: Recent searches list -->
<aside
  class="searches__sidebar rooms position-relative flex flex-column gap overflow-y overflow-hide-scrollbar"
>
  {#each recentSearches as search}
    <a
      href="/searches?q={encodeURIComponent(search.query)}"
      class="align-center gap room btn txt-nowrap"
    >
      <span class="overflow-ellipsis">"{search.query}"</span>
    </a>
  {/each}

  {#if recentSearches.length > 0}
    <button
      type="button"
      class="btn searches__btn"
      onclick={clearRecentSearches}
    >
      <img src={iconBroom} aria-hidden="true" alt="" />
      <span class="for-screen-reader">Clear recent searches</span>
    </button>
  {/if}
</aside>

<!-- Main content: Search results -->
<div id="message-area" class="message-area">
  {#if results.length === 0}
    <div class="message-area--empty min-width center">
      <figure class="center pad">
        <img
          src={iconSearch}
          aria-hidden="true"
          alt=""
          class="colorize--black translucent"
        />
      </figure>
    </div>
  {:else}
    <div class="search-results">
      {#each results as message}
        <SearchResultItem {message} />
      {/each}
    </div>
  {/if}
</div>

<!-- Footer content: Search form -->
<div class="composer flex align-end gap">
  <a
    href={returnToRoomPath}
    class="btn flex-item-no-shrink margin-block-end"
    style="view-transition-name: input-switcher; --btn-border-radius: 0.5em"
  >
    <img src={iconArrowLeft} aria-hidden="true" alt="" />
    <span class="for-screen-reader">Exit search</span>
  </a>

  <form
    onsubmit={handleSubmit}
    class="margin-block flex-item-grow contain flex align-center gap"
  >
    <div
      class="composer__input flex align-center flex-item-grow gap full-width input input--actor min-width"
    >
      <img
        src={iconSearch}
        width="20"
        height="20"
        aria-hidden="true"
        alt=""
        class="composer__input-hint colorize--black"
        style="view-transition-name: input-btn;"
      />

      <input
        type="text"
        name="q"
        bind:value={searchQuery}
        class="searches__input input flex-item-grow"
        role="searchbox"
        aria-label="search"
        use:focusContent
        required
      />

      <button type="button" onclick={clearSearch} class="searches__reset">
        <img
          src={iconRemove}
          aria-hidden="true"
          alt=""
          width="14"
          height="14"
          class="colorize--black"
        />
        <span class="for-screen-reader">Clear search field</span>
      </button>

      <button
        type="submit"
        class="btn btn--reversed flex-item-no-shrink txt-small"
        style="--btn-border-radius: 0.5em"
      >
        <img src={iconArrowUp} aria-hidden="true" alt="" />
        <span class="for-screen-reader">Search</span>
      </button>
    </div>
  </form>
</div>
