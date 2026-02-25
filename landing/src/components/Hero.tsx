"use client";

import { motion } from "framer-motion";
import { ArrowDown, Play, Download } from "lucide-react";

export default function Hero() {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden">
      {/* Grid background */}
      <div className="absolute inset-0 tron-grid-bg" />

      {/* Radial glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-tron-blue/5 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute top-1/3 right-1/4 w-[400px] h-[400px] bg-tron-orange/3 rounded-full blur-[100px] pointer-events-none" />

      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-24 pb-20">
        <div className="text-center">
          {/* Badge */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full border border-tron-blue/20 bg-tron-blue/5 mb-8"
          >
            <span className="w-2 h-2 rounded-full bg-tron-blue animate-pulse-glow" />
            <span className="text-xs font-mono text-tron-blue">
              v1.0 — Open Source
            </span>
          </motion.div>

          {/* Title */}
          <motion.h1
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.1 }}
            className="text-5xl sm:text-6xl lg:text-7xl font-extrabold tracking-tight mb-6"
          >
            <span className="text-white">TRON</span>
            <span className="text-tron-text-dim font-light"> — </span>
            <br className="hidden sm:block" />
            <span className="bg-gradient-to-r from-tron-blue to-tron-blue-dim bg-clip-text text-transparent">
              Sua Software House
            </span>
            <br />
            <span className="bg-gradient-to-r from-tron-orange to-tron-orange-dim bg-clip-text text-transparent">
              Autônoma
            </span>
          </motion.h1>

          {/* Tagline */}
          <motion.p
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="text-lg sm:text-xl text-tron-text-dim max-w-2xl mx-auto mb-10 leading-relaxed"
          >
            Agentes IA que programam, revisam e evoluem seus repos todos os
            dias.{" "}
            <span className="text-tron-blue font-medium">Você é o CIO.</span>
          </motion.p>

          {/* Buttons */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.3 }}
            className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-16"
          >
            <a href="#download" className="tron-btn-primary gap-2 text-base px-10 py-4">
              <Download className="w-5 h-5" />
              Download grátis
            </a>
            <a href="#como-funciona" className="tron-btn-secondary gap-2 text-base px-10 py-4">
              <Play className="w-5 h-5" />
              Ver demo
            </a>
          </motion.div>

          {/* App Screenshot Mockup */}
          <motion.div
            initial={{ opacity: 0, y: 50, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            transition={{ duration: 0.8, delay: 0.4 }}
            className="relative max-w-4xl mx-auto"
          >
            {/* Glow behind */}
            <div className="absolute -inset-4 bg-gradient-to-r from-tron-blue/20 via-transparent to-tron-orange/20 rounded-2xl blur-xl" />

            <div className="relative rounded-xl overflow-hidden border border-tron-border bg-tron-bg-card shadow-glow-blue">
              {/* Window chrome */}
              <div className="flex items-center gap-2 px-4 py-3 bg-tron-bg-light border-b border-tron-border">
                <div className="w-3 h-3 rounded-full bg-red-500/60" />
                <div className="w-3 h-3 rounded-full bg-yellow-500/60" />
                <div className="w-3 h-3 rounded-full bg-green-500/60" />
                <span className="ml-4 text-xs font-mono text-tron-text-dim">
                  TRON Dashboard — CIO Mode
                </span>
              </div>

              {/* Mock dashboard content */}
              <div className="p-6 space-y-4">
                <div className="grid grid-cols-3 gap-4">
                  {[
                    { label: "Agentes ativos", value: "12", color: "text-tron-blue" },
                    { label: "Commits hoje", value: "47", color: "text-green-400" },
                    { label: "PRs revisados", value: "8", color: "text-tron-orange" },
                  ].map((stat) => (
                    <div
                      key={stat.label}
                      className="p-4 rounded-lg bg-tron-bg/50 border border-tron-border"
                    >
                      <div className={`text-2xl font-bold font-mono ${stat.color}`}>
                        {stat.value}
                      </div>
                      <div className="text-xs text-tron-text-dim mt-1">
                        {stat.label}
                      </div>
                    </div>
                  ))}
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="p-4 rounded-lg bg-tron-bg/50 border border-tron-border space-y-2">
                    <div className="text-xs font-mono text-tron-blue mb-3">
                      Atividade dos agentes
                    </div>
                    {[
                      { name: "agent-backend", status: "Refatorando auth module", pct: 78 },
                      { name: "agent-frontend", status: "Criando componente UI", pct: 45 },
                      { name: "agent-tests", status: "Escrevendo testes e2e", pct: 92 },
                    ].map((agent) => (
                      <div key={agent.name} className="space-y-1">
                        <div className="flex justify-between text-xs">
                          <span className="text-tron-text font-mono">{agent.name}</span>
                          <span className="text-tron-text-dim">{agent.pct}%</span>
                        </div>
                        <div className="h-1.5 bg-tron-border rounded-full overflow-hidden">
                          <div
                            className="h-full bg-gradient-to-r from-tron-blue to-tron-blue-dim rounded-full"
                            style={{ width: `${agent.pct}%` }}
                          />
                        </div>
                      </div>
                    ))}
                  </div>
                  <div className="p-4 rounded-lg bg-tron-bg/50 border border-tron-border">
                    <div className="text-xs font-mono text-tron-orange mb-3">
                      Pipeline
                    </div>
                    <div className="space-y-2">
                      {[
                        { step: "Build", ok: true },
                        { step: "Tests", ok: true },
                        { step: "Lint", ok: true },
                        { step: "Deploy staging", ok: false },
                      ].map((s) => (
                        <div key={s.step} className="flex items-center gap-2 text-xs">
                          <span
                            className={`w-2 h-2 rounded-full ${
                              s.ok ? "bg-green-400" : "bg-yellow-400 animate-pulse"
                            }`}
                          />
                          <span className="text-tron-text-dim font-mono">{s.step}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>
        </div>

        {/* Scroll indicator */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1.2 }}
          className="flex justify-center mt-12"
        >
          <a
            href="#como-funciona"
            className="text-tron-text-dim hover:text-tron-blue transition-colors animate-bounce"
          >
            <ArrowDown className="w-5 h-5" />
          </a>
        </motion.div>
      </div>
    </section>
  );
}
