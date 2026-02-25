import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'Imperium Backend',
  tagline: 'API de Controle Financeiro Pessoal',
  favicon: 'img/favicon.ico',

  url: 'https://imperium-docs.example.com',
  baseUrl: '/',

  organizationName: 'imperium',
  projectName: 'imperium-backend',

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  i18n: {
    defaultLocale: 'pt-BR',
    locales: ['pt-BR'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          routeBasePath: '/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    colorMode: {
      defaultMode: 'dark',
      disableSwitch: false,
      respectPrefersColorScheme: false,
    },
    navbar: {
      title: 'Imperium',
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'tutorialSidebar',
          position: 'left',
          label: 'Docs',
        },
        {
          href: '/api/endpoints',
          label: 'API',
          position: 'left',
        },
        {
          href: 'http://localhost:8080/swagger/',
          label: 'Swagger',
          position: 'right',
        },
        {
          href: 'https://github.com/imperium',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Documentacao',
          items: [
            { label: 'Introducao', to: '/' },
            { label: 'API Reference', to: '/api/endpoints' },
            { label: 'Setup', to: '/guides/setup' },
          ],
        },
        {
          title: 'Links',
          items: [
            { label: 'Swagger UI', href: 'http://localhost:8080/swagger/' },
            { label: 'Grafana', href: 'http://localhost:3001' },
            { label: 'MongoDB Express', href: 'http://localhost:8081' },
          ],
        },
        {
          title: 'Stack',
          items: [
            { label: 'Go', href: 'https://go.dev' },
            { label: 'MongoDB', href: 'https://mongodb.com' },
            { label: 'Docker', href: 'https://docker.com' },
          ],
        },
      ],
      copyright: `Copyright ${new Date().getFullYear()} Imperium. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['go', 'bash', 'json', 'dart'],
    },
    tableOfContents: {
      minHeadingLevel: 2,
      maxHeadingLevel: 4,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
