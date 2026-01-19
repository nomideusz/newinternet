import { vitePreprocess } from "@sveltejs/vite-plugin-svelte"

export default {
  preprocess: vitePreprocess(),
  // Don't force runes globally - let each component opt-in or use legacy syntax
  // Our components use runes, but @inertiajs/svelte uses legacy Svelte 4 syntax
}
