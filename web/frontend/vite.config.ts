import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  base: '/PTIT_BANK_banking_management_system/',
  plugins: [react()],
  server: {
    port: 5173
  }
});
