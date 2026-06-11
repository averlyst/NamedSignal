import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  base: "/NamedSignal/",
  cleanUrls: true,

  title: "NamedSignal",
  description: "Documentation for NamedSignal — A signal implementation for Luau with a nice balance of ergonomics, performance, and features.",

  lastUpdated: true,

  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
      { text: 'API', link: '/api-reference/api-overview' }
    ],

    sidebar: [
      {
        text: 'Getting Started',
        items: [
          { text: 'Introduction', link: '/getting-started/introduction' },
          { text: 'Installation', link: '/getting-started/installation' },
		  { text: 'Quick Start', link: '/getting-started/quick-start' },
        ]
      },
	  {
        text: 'API Reference',
        items: [
		  { text: 'API Overview', link: '/api-reference/api-overview' },
          { text: 'Deferred Mutations', link: '/api-reference/deferred-mutations' },
        ]
      },
	  {
        text: 'Additional Info',
        items: [
		  { text: 'Performance', link: '/additional-info/performance' },
		  { text: 'Gohan\'s Certification', link: '/additional-info/gohans-certification' },
		  { text: 'Gotchas', link: '/additional-info/gotchas' },
		  { text: 'Future Considerations', link: '/additional-info/future-considerations' },
        ]
      }
    ],

	outline: [2, 3],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/Nowoshire/NamedSignal' },
	  { icon: 'robloxstudio', link: 'https://devforum.roblox.com/t/4341837' }
    ],

	search: {
		provider: "local"
	}
  },
})
