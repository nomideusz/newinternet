<script>
  import { onMount } from "svelte";

  let {
    autocompleteUrl,
    selectedUsers = $bindable([]),
    placeholder = "Type names to search…",
    required = false,
  } = $props();

  let query = $state("");
  let suggestions = $state([]);
  let isLoading = $state(false);
  let showDropdown = $state(false);
  let highlightedIndex = $state(-1);
  let inputElement = $state(null);
  let debounceTimer = $state(null);

  async function fetchSuggestions(searchQuery) {
    if (!searchQuery.trim()) {
      suggestions = [];
      showDropdown = false;
      return;
    }

    isLoading = true;
    try {
      const url = new URL(autocompleteUrl, window.location.origin);
      url.searchParams.set("query", searchQuery);
      const response = await fetch(url.toString(), {
        headers: { Accept: "application/json" },
      });
      if (response.ok) {
        const data = await response.json();
        suggestions = data.filter(
          (user) => !selectedUsers.some((s) => s.id === user.id),
        );
        showDropdown = suggestions.length > 0;
        highlightedIndex = -1;
      }
    } catch (error) {
      console.error("Failed to fetch suggestions:", error);
      suggestions = [];
    } finally {
      isLoading = false;
    }
  }

  function handleInput(event) {
    query = event.target.value;
    if (debounceTimer) clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => fetchSuggestions(query), 300);
  }

  function selectUser(user) {
    selectedUsers = [...selectedUsers, user];
    query = "";
    suggestions = [];
    showDropdown = false;
    highlightedIndex = -1;
    inputElement?.focus();
  }

  function removeUser(userId) {
    selectedUsers = selectedUsers.filter((u) => u.id !== userId);
  }

  function handleKeydown(event) {
    if (!showDropdown || suggestions.length === 0) {
      if (
        event.key === "Backspace" &&
        query === "" &&
        selectedUsers.length > 0
      ) {
        removeUser(selectedUsers[selectedUsers.length - 1].id);
      }
      return;
    }

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault();
        highlightedIndex = (highlightedIndex + 1) % suggestions.length;
        break;
      case "ArrowUp":
        event.preventDefault();
        highlightedIndex =
          highlightedIndex <= 0 ? suggestions.length - 1 : highlightedIndex - 1;
        break;
      case "Enter":
        event.preventDefault();
        if (highlightedIndex >= 0 && highlightedIndex < suggestions.length) {
          selectUser(suggestions[highlightedIndex]);
        }
        break;
      case "Escape":
        showDropdown = false;
        highlightedIndex = -1;
        break;
    }
  }

  function handleBlur(event) {
    setTimeout(() => {
      showDropdown = false;
    }, 150);
  }

  function handleFocus() {
    if (suggestions.length > 0) {
      showDropdown = true;
    }
  }

  onMount(() => {
    return () => {
      if (debounceTimer) clearTimeout(debounceTimer);
    };
  });
</script>

<section class="autocomplete__container unpad input input--actor">
  <div
    class="autocomplete__input input flex flex-wrap position-relative flex-item-grow"
  >
    {#each selectedUsers as user (user.id)}
      <div class="autocomplete__pill max-width" role="listitem">
        {#if user.avatar_url}
          <img
            class="avatar flex-item-no-shrink"
            src={user.avatar_url}
            alt=""
          />
        {/if}
        <span
          class="autocomplete-field__selected-value-text overflow-ellipsis flex-item-grow"
        >
          {user.name}
        </span>
        <button
          type="button"
          onclick={() => removeUser(user.id)}
          tabindex="-1"
          class="btn btn--plain txt-small translucent flex-item-no-shrink"
        >
          <img
            src={iconRemoveCircle}
            aria-hidden="true"
            class="colorize--black"
            alt=""
          />
          <span class="for-screen-reader">Remove {user.name}</span>
        </button>
      </div>
    {/each}

    <input
      bind:this={inputElement}
      type="text"
      value={query}
      oninput={handleInput}
      onkeydown={handleKeydown}
      onblur={handleBlur}
      onfocus={handleFocus}
      autocomplete="off"
      autocorrect="off"
      data-1p-ignore="true"
      class="autocomplete__text-input"
      {placeholder}
      {required}
    />

    {#if showDropdown}
      <div class="autocomplete__list">
        {#each suggestions as user, index (user.id)}
          <button
            type="button"
            class="autocomplete__btn autocomplete__item btn"
            class:highlighted={index === highlightedIndex}
            onmousedown={() => selectUser(user)}
            onmouseenter={() => (highlightedIndex = index)}
          >
            {#if user.avatar_url}
              <img class="avatar" src={user.avatar_url} alt="" />
            {/if}
            <span class="overflow-ellipsis">{user.name}</span>
          </button>
        {/each}
      </div>
    {/if}
  </div>

  {#each selectedUsers as user (user.id)}
    <input type="hidden" name="user_ids[]" value={user.id} />
  {/each}
</section>

<style>
  .autocomplete__text-input {
    background: transparent;
    border: none;
    flex: 1;
    min-width: 10ch;
    outline: none;
    padding: 0.3em;
  }

  .autocomplete__list {
    inset-block-start: 100%;
    inset-inline-start: 0;
  }

  .autocomplete__btn.highlighted {
    background-color: var(--color-text);
    color: var(--color-text-reversed);
  }
</style>
