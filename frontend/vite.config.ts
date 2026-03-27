import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "path";

// Set TYDAREN_FUNNEL_HOST (see npm run dev:funnel) so HMR uses wss:443 via Tailscale Funnel.
const funnelHost = (process.env.TYDAREN_FUNNEL_HOST ?? "").replace(/\.$/, "");

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    // Listen on all interfaces (LAN/Tailscale), same idea as uvicorn --host 0.0.0.0
    host: true,
    port: 5173,
    strictPort: true,
    // Tailscale MagicDNS hostnames when not using raw 100.x IP
    allowedHosts: [".ts.net", ".tailscale.net"],
    hmr: funnelHost
      ? {
          overlay: false,
          protocol: "wss",
          host: funnelHost,
          clientPort: 443,
        }
      : { overlay: false },
    proxy: {
      "/api": { target: "http://127.0.0.1:8000", changeOrigin: true },
    },
  },
  resolve: {
    alias: { "@": path.resolve(__dirname, "./src") },
  },
});
