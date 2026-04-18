import type { Config } from "tailwindcss";

export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        brand: {
          red: "#a51d2d",
          gold: "#d6a541",
          cream: "#fbf5e9",
          ink: "#2e1b16"
        }
      },
      fontFamily: {
        display: ["'Space Grotesk'", "sans-serif"],
        body: ["'Plus Jakarta Sans'", "sans-serif"]
      },
      boxShadow: {
        panel: "0 20px 40px rgba(90, 23, 31, 0.12)"
      },
      backgroundImage: {
        "hero-pattern":
          "radial-gradient(circle at top left, rgba(214,165,65,0.36), transparent 35%), radial-gradient(circle at 80% 20%, rgba(165,29,45,0.18), transparent 28%), linear-gradient(135deg, rgba(255,255,255,0.96), rgba(251,245,233,0.92))"
      }
    }
  },
  plugins: []
} satisfies Config;
