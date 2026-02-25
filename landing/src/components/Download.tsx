"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { Download as DownloadIcon, Apple, Monitor, Terminal, AlertCircle } from "lucide-react";

type OS = "macOS" | "Windows" | "Linux" | "unknown";

function detectOS(): OS {
  if (typeof navigator === "undefined") return "unknown";
  const ua = navigator.userAgent.toLowerCase();
  if (ua.includes("mac")) return "macOS";
  if (ua.includes("win")) return "Windows";
  if (ua.includes("linux")) return "Linux";
  return "unknown";
}

const osConfig: Record<
  Exclude<OS, "unknown">,
  { icon: typeof Apple; label: string; file: string; cmd: string }
> = {
  macOS: {
    icon: Apple,
    label: "macOS",
    file: "tron-darwin-arm64.dmg",
    cmd: "brew install tron",
  },
  Windows: {
    icon: Monitor,
    label: "Windows",
    file: "tron-win-x64.exe",
    cmd: "winget install tron",
  },
  Linux: {
    icon: Terminal,
    label: "Linux",
    file: "tron-linux-x64.AppImage",
    cmd: "curl -fsSL https://tron.dev/install.sh | sh",
  },
};

const requirements = [
  { name: "Docker", description: "v24+ instalado e rodando" },
  { name: "GitHub Account", description: "Com acesso aos repos desejados" },
  { name: "API Key Anthropic", description: "Claude API para os agentes IA" },
];

export default function Download() {
  const [detectedOS, setDetectedOS] = useState<OS>("unknown");

  useEffect(() => {
    setDetectedOS(detectOS());
  }, []);

  const primaryOS = detectedOS !== "unknown" ? detectedOS : "macOS";

  return (
    <section id="download" className="relative py-24 sm:py-32">
      <div className="absolute inset-0 tron-grid-bg opacity-40" />
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-tron-orange/5 rounded-full blur-[150px] pointer-events-none" />

      <div className="relative z-10 max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6 }}
          className="text-center mb-12"
        >
          <h2 className="text-3xl sm:text-4xl font-bold text-white mb-4">
            Download TRON
          </h2>
          <p className="text-tron-text-dim max-w-lg mx-auto">
            Disponível para macOS, Windows e Linux. Instale em segundos e
            comece a automatizar.
          </p>
        </motion.div>

        {/* Primary download button */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="text-center mb-8"
        >
          <a
            href="#"
            className="tron-btn-primary gap-3 text-lg px-12 py-5 inline-flex"
          >
            <DownloadIcon className="w-6 h-6" />
            Download para {primaryOS}
          </a>
          <p className="text-xs text-tron-text-dim mt-3 font-mono">
            {osConfig[primaryOS].file}
          </p>
        </motion.div>

        {/* All OS buttons */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="flex flex-wrap justify-center gap-4 mb-16"
        >
          {(Object.entries(osConfig) as [Exclude<OS, "unknown">, typeof osConfig.macOS][]).map(
            ([os, config]) => (
              <a
                key={os}
                href="#"
                className={`inline-flex items-center gap-2 px-6 py-3 rounded-lg text-sm font-medium transition-all duration-300 ${
                  os === primaryOS
                    ? "bg-tron-blue/15 border border-tron-blue/40 text-tron-blue"
                    : "bg-tron-bg-card border border-tron-border text-tron-text-dim hover:border-tron-blue/30 hover:text-tron-text"
                }`}
              >
                <config.icon className="w-4 h-4" />
                {config.label}
              </a>
            )
          )}
        </motion.div>

        {/* Terminal install */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5, delay: 0.3 }}
          className="max-w-lg mx-auto mb-16"
        >
          <div className="rounded-lg overflow-hidden border border-tron-border">
            <div className="flex items-center gap-2 px-4 py-2 bg-tron-bg-light border-b border-tron-border">
              <div className="w-2.5 h-2.5 rounded-full bg-red-500/50" />
              <div className="w-2.5 h-2.5 rounded-full bg-yellow-500/50" />
              <div className="w-2.5 h-2.5 rounded-full bg-green-500/50" />
              <span className="ml-2 text-[10px] font-mono text-tron-text-dim">
                Terminal
              </span>
            </div>
            <div className="p-4 bg-tron-bg-card">
              <code className="text-sm font-mono text-tron-blue">
                $ {osConfig[primaryOS].cmd}
              </code>
            </div>
          </div>
        </motion.div>

        {/* Requirements */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5, delay: 0.4 }}
        >
          <h3 className="text-lg font-semibold text-white text-center mb-6">
            Requisitos
          </h3>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            {requirements.map((req) => (
              <div
                key={req.name}
                className="flex items-start gap-3 p-4 rounded-lg bg-tron-bg-card border border-tron-border"
              >
                <AlertCircle className="w-4 h-4 text-tron-orange flex-shrink-0 mt-0.5" />
                <div>
                  <div className="text-sm font-medium text-white">{req.name}</div>
                  <div className="text-xs text-tron-text-dim">{req.description}</div>
                </div>
              </div>
            ))}
          </div>
        </motion.div>
      </div>
    </section>
  );
}
