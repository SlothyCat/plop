// @ts-check
/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'plop',
  tagline: 'A local-first iOS expense tracker, built with a disciplined AI-assisted workflow.',
  favicon: 'img/favicon.ico',
  url: 'https://slothycat.github.io',
  baseUrl: '/plop/',
  organizationName: 'SlothyCat',
  projectName: 'plop',
  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',
  trailingSlash: false,
  markdown: { format: 'detect' },
  i18n: { defaultLocale: 'en', locales: ['en'] },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          path: '../docs',
          routeBasePath: 'reference',
          sidebarPath: require.resolve('./sidebars.js'),
          admonitions: { keywords: ['voice'], extendDefaults: true },
        },
        blog: false,
        theme: { customCss: require.resolve('./src/css/custom.css') },
      }),
    ],
  ],

  plugins: [
    [
      '@docusaurus/plugin-content-docs',
      {
        id: 'story',
        path: 'story',
        routeBasePath: 'story',
        sidebarPath: require.resolve('./sidebarsStory.js'),
        admonitions: { keywords: ['voice'], extendDefaults: true },
      },
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      navbar: {
        title: 'plop',
        items: [
          { to: '/story/overview', label: 'The Story', position: 'left' },
          { to: '/reference/roadmap', label: 'Reference', position: 'left' },
          { href: 'https://github.com/SlothyCat/plop', label: 'GitHub', position: 'right' },
        ],
      },
      footer: {
        style: 'light',
        copyright: `Built by SlothyCat. Docs powered by Docusaurus.`,
      },
    }),
};

module.exports = config;
