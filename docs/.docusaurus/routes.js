import React from 'react';
import ComponentCreator from '@docusaurus/ComponentCreator';

export default [
  {
    path: '/__docusaurus/debug',
    component: ComponentCreator('/__docusaurus/debug', '5ff'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/config',
    component: ComponentCreator('/__docusaurus/debug/config', '5ba'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/content',
    component: ComponentCreator('/__docusaurus/debug/content', 'a2b'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/globalData',
    component: ComponentCreator('/__docusaurus/debug/globalData', 'c3c'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/metadata',
    component: ComponentCreator('/__docusaurus/debug/metadata', '156'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/registry',
    component: ComponentCreator('/__docusaurus/debug/registry', '88c'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/routes',
    component: ComponentCreator('/__docusaurus/debug/routes', '000'),
    exact: true
  },
  {
    path: '/',
    component: ComponentCreator('/', '785'),
    routes: [
      {
        path: '/',
        component: ComponentCreator('/', 'c54'),
        routes: [
          {
            path: '/',
            component: ComponentCreator('/', 'fb5'),
            routes: [
              {
                path: '/api/authentication',
                component: ComponentCreator('/api/authentication', '255'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/api/endpoints',
                component: ComponentCreator('/api/endpoints', '6cf'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/api/models',
                component: ComponentCreator('/api/models', 'd72'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/architecture/database',
                component: ComponentCreator('/architecture/database', '669'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/architecture/overview',
                component: ComponentCreator('/architecture/overview', '4fe'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/guides/deployment',
                component: ComponentCreator('/guides/deployment', 'c92'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/guides/documentation-standards',
                component: ComponentCreator('/guides/documentation-standards', '8ee'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/guides/setup',
                component: ComponentCreator('/guides/setup', 'e83'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/tron/agents',
                component: ComponentCreator('/tron/agents', '444'),
                exact: true
              },
              {
                path: '/tron/api',
                component: ComponentCreator('/tron/api', '481'),
                exact: true
              },
              {
                path: '/tron/overview',
                component: ComponentCreator('/tron/overview', 'ed3'),
                exact: true
              },
              {
                path: '/',
                component: ComponentCreator('/', 'fc9'),
                exact: true,
                sidebar: "tutorialSidebar"
              }
            ]
          }
        ]
      }
    ]
  },
  {
    path: '*',
    component: ComponentCreator('*'),
  },
];
