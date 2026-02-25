import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  tutorialSidebar: [
    'intro',
    {
      type: 'category',
      label: 'API',
      collapsed: false,
      items: [
        'api/endpoints',
        'api/models',
        'api/authentication',
      ],
    },
    {
      type: 'category',
      label: 'Guias',
      items: [
        'guides/setup',
        'guides/deployment',
        'guides/documentation-standards',
      ],
    },
    {
      type: 'category',
      label: 'Arquitetura',
      items: [
        'architecture/overview',
        'architecture/database',
      ],
    },
  ],
};

export default sidebars;
