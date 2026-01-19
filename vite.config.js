import { defineConfig } from "vite";
import { svelte } from "@sveltejs/vite-plugin-svelte";
import { fileURLToPath } from "url";
import { dirname, resolve } from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export default defineConfig({
  plugins: [svelte()],
  resolve: {
    alias: {
      "@": resolve(__dirname, "app/frontend"),
      images: resolve(__dirname, "app/assets/images"),
    },
  },
  root: resolve(__dirname),
  publicDir: resolve(__dirname, "public"),
  server: {
    port: 3036,
    strictPort: false,
    host: "0.0.0.0",
    cors: true,
    hmr: {
      // Use clientPort to ensure browser connects to the right port
      clientPort: 3036,
      // Don't specify host - let it auto-detect from the browser's location
      // This works whether you access via localhost, 127.0.0.1, or any other hostname
    },
    watch: {
      // Enable polling for Docker volumes (file changes may not trigger otherwise)
      usePolling: true,
      interval: 1000,
    },
    // Allow requests from any origin
    allowedHosts: "all",
  },
  build: {
    manifest: true,
    outDir: resolve(__dirname, "public/vite"),
    rollupOptions: {
      input: resolve(__dirname, "app/frontend/entrypoints/inertia.js"),
    },
  },
});
