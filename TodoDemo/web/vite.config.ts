import react from "@vitejs/plugin-react";
import {defineConfig} from "vite";

const backendUrl = "http://localhost:5200";

export default defineConfig({
    plugins: [react()],
    server: {
        port: 3000,
        host: "127.0.0.1",
        open: false,
        proxy: {
            "/api": {
                target: backendUrl,
                changeOrigin: true,
            },
            "/todoHub": {
                target: backendUrl,
                changeOrigin: true,
                ws: true,
            },
        },
    },
});
