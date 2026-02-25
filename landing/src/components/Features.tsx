"use client";

import { motion } from "framer-motion";
import {
  Bot,
  LayoutDashboard,
  RefreshCw,
  FolderGit2,
  Kanban,
  ShieldCheck,
} from "lucide-react";

const features = [
  {
    icon: Bot,
    title: "Multi-agentes",
    description:
      "Múltiplos agentes IA trabalhando em paralelo: backend, frontend, testes, docs. Cada um especializado na sua função.",
  },
  {
    icon: LayoutDashboard,
    title: "Dashboard CIO",
    description:
      "Visão executiva de todos os projetos, agentes, métricas de produtividade e histórico de evolução em tempo real.",
  },
  {
    icon: RefreshCw,
    title: "Evolução contínua",
    description:
      "Ciclos automáticos de desenvolvimento todos os dias. Seu codebase evolui mesmo enquanto você dorme.",
  },
  {
    icon: FolderGit2,
    title: "Multi-repo",
    description:
      "Gerencie múltiplos repositórios simultaneamente. Frontend, backend, infra — tudo sincronizado e coordenado.",
  },
  {
    icon: Kanban,
    title: "Kanban autônomo",
    description:
      "Board de tasks que se auto-gerencia. Agentes pegam tasks, estimam, executam e movem para done automaticamente.",
  },
  {
    icon: ShieldCheck,
    title: "Review automático",
    description:
      "Todo código passa por review automático antes do merge. Qualidade, segurança e padrões verificados por IA.",
  },
];

const containerVariants = {
  hidden: {},
  visible: {
    transition: { staggerChildren: 0.1 },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 30 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.5, ease: "easeOut" },
  },
};

export default function Features() {
  return (
    <section id="features" className="relative py-24 sm:py-32">
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[600px] bg-tron-blue/3 rounded-full blur-[150px] pointer-events-none" />

      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-3xl sm:text-4xl font-bold text-white mb-4">
            Tudo que você precisa
          </h2>
          <p className="text-tron-text-dim max-w-xl mx-auto">
            Uma plataforma completa para automatizar seu desenvolvimento com agentes IA.
          </p>
        </motion.div>

        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-50px" }}
          className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6"
        >
          {features.map((feature) => (
            <motion.div
              key={feature.title}
              variants={itemVariants}
              className="tron-card rounded-xl p-6 group"
            >
              <div className="w-12 h-12 rounded-lg bg-tron-blue/10 border border-tron-blue/20 flex items-center justify-center mb-5 group-hover:bg-tron-blue/15 transition-colors">
                <feature.icon className="w-6 h-6 text-tron-blue" />
              </div>
              <h3 className="text-lg font-semibold text-white mb-2">
                {feature.title}
              </h3>
              <p className="text-sm text-tron-text-dim leading-relaxed">
                {feature.description}
              </p>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  );
}
