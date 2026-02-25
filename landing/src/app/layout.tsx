import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "TRON — Sua Software House Autônoma",
  description:
    "Agentes IA que programam, revisam e evoluem seus repos todos os dias. Você é o CIO. Download grátis para macOS, Windows e Linux.",
  keywords: [
    "TRON",
    "IA",
    "agentes",
    "software house",
    "automação",
    "código",
    "multi-agentes",
    "developer tools",
  ],
  authors: [{ name: "TRON" }],
  openGraph: {
    title: "TRON — Sua Software House Autônoma",
    description:
      "Agentes IA que programam, revisam e evoluem seus repos todos os dias. Você é o CIO.",
    type: "website",
    locale: "pt_BR",
    siteName: "TRON",
    images: [
      {
        url: "/og-image.png",
        width: 1200,
        height: 630,
        alt: "TRON — Sua Software House Autônoma",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "TRON — Sua Software House Autônoma",
    description:
      "Agentes IA que programam, revisam e evoluem seus repos todos os dias.",
    images: ["/og-image.png"],
  },
  robots: {
    index: true,
    follow: true,
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="pt-BR" className="antialiased">
      <body className="bg-tron-bg text-tron-text">{children}</body>
    </html>
  );
}
