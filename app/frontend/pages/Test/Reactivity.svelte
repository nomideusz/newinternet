<script>
  import { onMount, onDestroy, untrack } from "svelte";

  let { page, sidebar = {}, currentUser = null } = $props();

  // Sidebar is now mounted by the global sidebarManager in inertia.js

  // ============================================
  // 1. Basic $state - Simple counter
  // ============================================
  let count = $state(0);

  // ============================================
  // 2. $derived - Computed values
  // ============================================
  let doubled = $derived(count * 2);
  let quadrupled = $derived(doubled * 2);
  let isEven = $derived(count % 2 === 0);

  // ============================================
  // 3. Reactive text input
  // ============================================
  let name = $state("");
  let greeting = $derived(name ? `Hello, ${name}!` : "Enter your name...");
  let nameLength = $derived(name.length);

  // ============================================
  // 4. Reactive array - Todo list
  // ============================================
  let todos = $state([
    { id: 1, text: "Learn Svelte 5", done: true },
    { id: 2, text: "Build something cool", done: false },
    { id: 3, text: "Ship it!", done: false },
  ]);
  let newTodo = $state("");
  let nextId = $state(4);

  let completedCount = $derived(todos.filter((t) => t.done).length);
  let remainingCount = $derived(todos.length - completedCount);

  function addTodo() {
    if (newTodo.trim()) {
      todos.push({ id: nextId++, text: newTodo.trim(), done: false });
      newTodo = "";
    }
  }

  function removeTodo(id) {
    todos = todos.filter((t) => t.id !== id);
  }

  function toggleTodo(todo) {
    todo.done = !todo.done;
  }

  // ============================================
  // 5. $effect - Side effects & logging
  // ============================================
  let effectLog = $state([]);

  $effect(() => {
    // Track count changes, but don't track effectLog reads to avoid infinite loop
    const currentCount = count;
    const message = `Count changed to ${currentCount} at ${new Date().toLocaleTimeString()}`;
    untrack(() => {
      effectLog = [...effectLog.slice(-4), message];
    });
  });

  // ============================================
  // 6. Timer example - Auto-updating clock
  // ============================================
  let time = $state(new Date());
  let timerInterval = null;

  onMount(() => {
    timerInterval = setInterval(() => {
      time = new Date();
    }, 1000);
  });

  onDestroy(() => {
    if (timerInterval) clearInterval(timerInterval);
  });

  let formattedTime = $derived(
    time.toLocaleTimeString("en-US", {
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    })
  );

  // ============================================
  // 7. Color picker - RGB sliders
  // ============================================
  let red = $state(100);
  let green = $state(150);
  let blue = $state(200);
  let rgbColor = $derived(`rgb(${red}, ${green}, ${blue})`);
  let hexColor = $derived(
    `#${red.toString(16).padStart(2, "0")}${green.toString(16).padStart(2, "0")}${blue.toString(16).padStart(2, "0")}`
  );
</script>

<svelte:head>
  <title>Svelte Reactivity Test</title>
</svelte:head>

<div class="test-page" style="padding: 2rem; max-width: 800px; margin: 0 auto;">
  <h1 style="margin-bottom: 2rem;">🧪 Svelte 5 Reactivity Test</h1>

  <!-- 1. Counter -->
  <section class="test-section">
    <h2>1. Basic Counter ($state)</h2>
    <div class="flex gap align-center">
      <button class="btn" onclick={() => count--}>−</button>
      <span style="font-size: 2rem; min-width: 4rem; text-align: center;">{count}</span>
      <button class="btn" onclick={() => count++}>+</button>
      <button class="btn btn--reversed" onclick={() => (count = 0)}>Reset</button>
    </div>
  </section>

  <!-- 2. Derived values -->
  <section class="test-section">
    <h2>2. Derived Values ($derived)</h2>
    <ul>
      <li>Count: <strong>{count}</strong></li>
      <li>Doubled: <strong>{doubled}</strong></li>
      <li>Quadrupled: <strong>{quadrupled}</strong></li>
      <li>Is even: <strong>{isEven ? "Yes ✅" : "No ❌"}</strong></li>
    </ul>
  </section>

  <!-- 3. Text input -->
  <section class="test-section">
    <h2>3. Reactive Text Input</h2>
    <input
      type="text"
      bind:value={name}
      placeholder="Type your name..."
      class="input"
      style="padding: 0.5rem; width: 100%; max-width: 300px;"
    />
    <p style="font-size: 1.2rem; margin-top: 0.5rem;">{greeting}</p>
    <p class="txt-small translucent">Characters: {nameLength}</p>
  </section>

  <!-- 4. Todo list -->
  <section class="test-section">
    <h2>4. Reactive Array (Todo List)</h2>
    <div class="flex gap" style="margin-bottom: 1rem;">
      <input
        type="text"
        bind:value={newTodo}
        placeholder="Add a todo..."
        class="input"
        style="padding: 0.5rem; flex: 1;"
        onkeydown={(e) => e.key === "Enter" && addTodo()}
      />
      <button class="btn btn--reversed" onclick={addTodo}>Add</button>
    </div>
    <ul style="list-style: none; padding: 0;">
      {#each todos as todo (todo.id)}
        <li class="flex gap align-center" style="padding: 0.5rem 0; border-bottom: 1px solid var(--color-border);">
          <input
            type="checkbox"
            checked={todo.done}
            onchange={() => toggleTodo(todo)}
            style="width: 1.2rem; height: 1.2rem;"
          />
          <span style="flex: 1; text-decoration: {todo.done ? 'line-through' : 'none'}; opacity: {todo.done ? 0.5 : 1};">
            {todo.text}
          </span>
          <button class="btn txt-small" onclick={() => removeTodo(todo.id)}>🗑️</button>
        </li>
      {/each}
    </ul>
    <p class="txt-small translucent">
      {completedCount} completed, {remainingCount} remaining
    </p>
  </section>

  <!-- 5. Effect log -->
  <section class="test-section">
    <h2>5. Side Effects ($effect)</h2>
    <p class="txt-small translucent">Change the counter above to see effects logged:</p>
    <div style="background: var(--color-message-bg); padding: 1rem; border-radius: 0.5rem; font-family: monospace; font-size: 0.85rem;">
      {#each effectLog as log}
        <div>{log}</div>
      {/each}
      {#if effectLog.length === 0}
        <div class="translucent">No effects yet...</div>
      {/if}
    </div>
  </section>

  <!-- 6. Clock -->
  <section class="test-section">
    <h2>6. Auto-updating Clock</h2>
    <div style="font-size: 3rem; font-family: monospace; text-align: center;">
      {formattedTime}
    </div>
  </section>

  <!-- 7. Color picker -->
  <section class="test-section">
    <h2>7. RGB Color Picker</h2>
    <div class="flex gap" style="margin-bottom: 1rem;">
      <label style="flex: 1;">
        R: {red}
        <input type="range" min="0" max="255" bind:value={red} style="width: 100%;" />
      </label>
      <label style="flex: 1;">
        G: {green}
        <input type="range" min="0" max="255" bind:value={green} style="width: 100%;" />
      </label>
      <label style="flex: 1;">
        B: {blue}
        <input type="range" min="0" max="255" bind:value={blue} style="width: 100%;" />
      </label>
    </div>
    <div class="flex gap align-center">
      <div
        style="width: 100px; height: 100px; border-radius: 0.5rem; border: 2px solid var(--color-border); background-color: {rgbColor};"
      ></div>
      <div>
        <p><strong>RGB:</strong> {rgbColor}</p>
        <p><strong>HEX:</strong> {hexColor}</p>
      </div>
    </div>
  </section>
</div>

<style>
  .test-section {
    background: var(--color-bg);
    border: 1px solid var(--color-border);
    border-radius: 0.5rem;
    padding: 1.5rem;
    margin-bottom: 1.5rem;
  }

  .test-section h2 {
    margin: 0 0 1rem 0;
    font-size: 1.1rem;
    color: var(--color-selected-dark);
  }

  .test-section ul {
    margin: 0;
    padding-left: 1.5rem;
  }

  .test-section li {
    margin: 0.25rem 0;
  }
</style>
