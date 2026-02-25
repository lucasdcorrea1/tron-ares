"use client";

import { motion } from "framer-motion";
import { Check, Zap } from "lucide-react";

const plans = [
  {
    name: "Free",
    price: "$0",
    period: "para sempre",
    description: "Para experimentar e projetos pessoais.",
    features: [
      "1 projeto",
      "2 repositórios",
      "5 ciclos por dia",
      "1 agente simultâneo",
      "Dashboard básico",
      "Community support",
    ],
    cta: "Começar grátis",
    href: "#download",
    highlighted: false,
  },
  {
    name: "Pro",
    price: "$29",
    period: "/mês",
    description: "Para devs e times pequenos que querem escalar.",
    features: [
      "Projetos ilimitados",
      "Repos ilimitados",
      "Ciclos ilimitados",
      "Agentes ilimitados",
      "Dashboard completo",
      "Prioridade no suporte",
      "Agentes customizados",
      "Webhooks & API",
    ],
    cta: "Começar com Pro",
    href: "#download",
    highlighted: true,
  },
  {
    name: "Team",
    price: "$79",
    period: "/mês",
    description: "Para equipes que precisam de colaboração.",
    features: [
      "Tudo do Pro",
      "Multi-user",
      "Roles & permissões",
      "Audit log",
      "SSO / SAML",
      "SLA dedicado",
      "Onboarding guiado",
      "Suporte prioritário",
    ],
    cta: "Falar com vendas",
    href: "#download",
    highlighted: false,
  },
];

const containerVariants = {
  hidden: {},
  visible: {
    transition: { staggerChildren: 0.15 },
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

export default function Pricing() {
  return (
    <section id="pricing" className="relative py-24 sm:py-32">
      <div className="absolute inset-0 tron-grid-bg opacity-30" />

      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-3xl sm:text-4xl font-bold text-white mb-4">
            Preços simples
          </h2>
          <p className="text-tron-text-dim max-w-xl mx-auto">
            Comece grátis. Escale quando precisar.
          </p>
        </motion.div>

        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-50px" }}
          className="grid grid-cols-1 md:grid-cols-3 gap-8 items-start"
        >
          {plans.map((plan) => (
            <motion.div
              key={plan.name}
              variants={itemVariants}
              className={`relative rounded-xl p-8 ${
                plan.highlighted
                  ? "bg-gradient-to-b from-tron-blue/10 to-tron-bg-card border-2 border-tron-blue/40 shadow-glow-blue"
                  : "tron-card"
              }`}
            >
              {plan.highlighted && (
                <div className="absolute -top-3.5 left-1/2 -translate-x-1/2">
                  <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full bg-tron-blue text-tron-bg text-xs font-semibold">
                    <Zap className="w-3 h-3" />
                    Mais popular
                  </span>
                </div>
              )}

              <div className="mb-6">
                <h3 className="text-lg font-semibold text-white mb-1">
                  {plan.name}
                </h3>
                <p className="text-sm text-tron-text-dim">{plan.description}</p>
              </div>

              <div className="mb-6">
                <span className="text-4xl font-bold text-white">{plan.price}</span>
                <span className="text-tron-text-dim ml-1">{plan.period}</span>
              </div>

              <ul className="space-y-3 mb-8">
                {plan.features.map((feature) => (
                  <li key={feature} className="flex items-start gap-3 text-sm">
                    <Check className="w-4 h-4 text-tron-blue flex-shrink-0 mt-0.5" />
                    <span className="text-tron-text">{feature}</span>
                  </li>
                ))}
              </ul>

              <a
                href={plan.href}
                className={`w-full ${
                  plan.highlighted ? "tron-btn-primary" : "tron-btn-secondary"
                }`}
              >
                {plan.cta}
              </a>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  );
}
