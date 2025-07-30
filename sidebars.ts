import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

/**
 * Creating a sidebar enables you to:
 - create an ordered group of docs
 - render a sidebar for each doc of that group
 - provide next/previous navigation

 The sidebars can be generated from the filesystem, or explicitly defined here.

 Create as many sidebars as you want.
 */
const sidebars: SidebarsConfig = {
  // By default, Docusaurus generates a sidebar from the docs folder structure
  docsSidebar: [
    'getting-started',
    'README',
    {
      type: 'category',
      label: 'Core Concepts',
      items: [
        'language-model-session',
        'generable-protocol',
        'tool-protocol',
        'swiftui-integration',
      ],
    },
    {
      type: 'category',
      label: 'API Reference',
      items: [
        'api-reference',
        'common-patterns',
      ],
    },
    {
      type: 'category',
      label: 'Examples',
      items: [
        'examples/text-summarization',
        'examples/content-generation',
        'examples/travel-planning',
      ],
    },
    'DOCUMENTATION_SUMMARY',
  ],
};

export default sidebars;
