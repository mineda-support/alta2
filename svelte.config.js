import adapter from '@sveltejs/adapter-auto';
import { markdoc } from 'svelte-markdoc-preprocess';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';
//import { vitePreprocess } from '@sveltejs/kit/vite';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	kit: {
		// adapter-auto only supports some environments, see https://svelte.dev/docs/kit/adapter-auto for a list.
		// If your environment is not supported, or you settled on a specific environment, switch out the adapter.
		// See https://svelte.dev/docs/kit/adapters for more information about adapters.
		adapter: adapter()
	},
	preprocess:
		[vitePreprocess(),
		markdoc({
			})],
	extensions: ['.markdoc', '.svelte'],
};

export default config;

//export default {
//	preprocess: [vitePreprocess()]
//};
