"use client";

import { motion } from "framer-motion";
import { Zap, Github, MessageCircle, BookOpen, PenLine } from "lucide-react";

const links = [
  { icon: Github, label: "GitHub", href: "https://github.com/tron-dev" },
  { icon: MessageCircle, label: "Discord", href: "#" },
  { icon: BookOpen, label: "Docs", href: "#" },
  { icon: PenLine, label: "Blog", href: "#" },
];

export default function Footer() {
  return (
    <footer className="relative border-t border-tron-border">
      <div className="absolute inset-0 tron-grid-bg opacity-20" />

      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="flex flex-col md:flex-row items-center justify-between gap-8"
        >
          {/* Logo + tagline */}
          <div className="flex flex-col items-center md:items-start gap-2">
            <div className="flex items-center gap-2">
              <Zap className="w-5 h-5 text-tron-blue" />
              <span className="text-lg font-bold tracking-wider text-white">
                TRON
              </span>
            </div>
            <p className="text-xs text-tron-text-dim font-mono italic">
              Built by programs, for programs.
            </p>
          </div>

          {/* Links */}
          <div className="flex items-center gap-6">
            {links.map((link) => (
              <a
                key={link.label}
                href={link.href}
                className="flex items-center gap-1.5 text-sm text-tron-text-dim hover:text-tron-blue transition-colors duration-200"
                target="_blank"
                rel="noopener noreferrer"
              >
                <link.icon className="w-4 h-4" />
                <span className="hidden sm:inline">{link.label}</span>
              </a>
            ))}
          </div>
        </motion.div>

        <div className="mt-8 pt-6 border-t border-tron-border/50 text-center">
          <p className="text-xs text-tron-text-dim">
            &copy; {new Date().getFullYear()} TRON. Todos os direitos reservados.
          </p>
        </div>
      </div>
    </footer>
  );
}
