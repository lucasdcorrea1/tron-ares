"use client";

import { motion } from "framer-motion";
import { GitBranch, Settings, Coffee } from "lucide-react";

const steps = [
  {
    icon: GitBranch,
    title: "Conecte",
    description:
      "Conecte seus repositórios GitHub. O TRON clona, analisa a estrutura e entende seu codebase automaticamente.",
    step: "01",
  },
  {
    icon: Settings,
    title: "Configure",
    description:
      "Defina tasks no Kanban, escolha agentes e configure ciclos. O TRON planeja sprints e distribui trabalho.",
    step: "02",
  },
  {
    icon: Coffee,
    title: "Relaxe",
    description:
      "Agentes programam, fazem commits, abrem PRs e revisam código. Você acompanha tudo pelo dashboard de CIO.",
    step: "03",
  },
];

const containerVariants = {
  hidden: {},
  visible: {
    transition: { staggerChildren: 0.2 },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 40 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.6, ease: "easeOut" },
  },
};

export default function HowItWorks() {
  return (
    <section id="como-funciona" className="relative py-24 sm:py-32">
      <div className="absolute inset-0 tron-grid-bg opacity-50" />

      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-3xl sm:text-4xl font-bold text-white mb-4">
            Como funciona
          </h2>
          <p className="text-tron-text-dim max-w-xl mx-auto">
            Três passos para transformar seus repos em projetos que evoluem sozinhos.
          </p>
        </motion.div>

        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-100px" }}
          className="grid grid-cols-1 md:grid-cols-3 gap-8"
        >
          {steps.map((step, i) => (
            <motion.div key={step.title} variants={itemVariants} className="relative">
              {/* Connector line */}
              {i < steps.length - 1 && (
                <div className="hidden md:block absolute top-16 left-[calc(50%+60px)] w-[calc(100%-120px)] h-px bg-gradient-to-r from-tron-blue/30 to-tron-blue/10" />
              )}

              <div className="tron-card rounded-xl p-8 text-center h-full">
                <div className="inline-flex items-center justify-center w-16 h-16 rounded-xl bg-tron-blue/10 border border-tron-blue/20 mb-6 relative">
                  <step.icon className="w-7 h-7 text-tron-blue" />
                  <span className="absolute -top-2 -right-2 w-6 h-6 rounded-full bg-tron-bg border border-tron-blue/30 flex items-center justify-center text-[10px] font-mono text-tron-blue">
                    {step.step}
                  </span>
                </div>
                <h3 className="text-xl font-bold text-white mb-3">{step.title}</h3>
                <p className="text-sm text-tron-text-dim leading-relaxed">
                  {step.description}
                </p>
              </div>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  );
}
