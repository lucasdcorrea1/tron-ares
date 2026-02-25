import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        tron: {
          bg: "#0a0a0f",
          "bg-light": "#12121a",
          "bg-card": "#16161f",
          blue: "#00D4FF",
          "blue-dim": "#0099bb",
          orange: "#FF6B00",
          "orange-dim": "#cc5500",
          grid: "#1a1a2e",
          border: "#2a2a3e",
          text: "#e0e0e0",
          "text-dim": "#888899",
        },
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"],
        mono: ["JetBrains Mono", "monospace"],
      },
      boxShadow: {
        "glow-blue": "0 0 20px rgba(0, 212, 255, 0.3), 0 0 60px rgba(0, 212, 255, 0.1)",
        "glow-blue-lg": "0 0 30px rgba(0, 212, 255, 0.4), 0 0 80px rgba(0, 212, 255, 0.15)",
        "glow-orange": "0 0 20px rgba(255, 107, 0, 0.3), 0 0 60px rgba(255, 107, 0, 0.1)",
        "glow-card": "0 0 0 1px rgba(0, 212, 255, 0.1), 0 4px 30px rgba(0, 0, 0, 0.5)",
      },
      backgroundImage: {
        "grid-pattern":
          "linear-gradient(rgba(0, 212, 255, 0.03) 1px, transparent 1px), linear-gradient(90deg, rgba(0, 212, 255, 0.03) 1px, transparent 1px)",
      },
      backgroundSize: {
        grid: "60px 60px",
      },
      animation: {
        "pulse-glow": "pulse-glow 3s ease-in-out infinite",
        float: "float 6s ease-in-out infinite",
      },
      keyframes: {
        "pulse-glow": {
          "0%, 100%": { opacity: "0.4" },
          "50%": { opacity: "1" },
        },
        float: {
          "0%, 100%": { transform: "translateY(0)" },
          "50%": { transform: "translateY(-10px)" },
        },
      },
    },
  },
  plugins: [],
};

export default config;
