<script lang="ts">
  import Markdown from 'svelte-exmarkdown';
 	import { gfmPlugin } from 'svelte-exmarkdown/gfm';
  import { tooltip, msg } from "../Utils/tooltip.svelte";
  async function save_markdown(md_data, md_file) {
    const props = {};
    props.md_data = md_data;
    props.md_file = md_file;
    const response = await fetch("markdown_docs", {
      method: "POST",
      body: JSON.stringify(props),
      headers: {
        "Content-Type": "application/json",
      },
    });
  }

  async function load_markdown(md_file, dir) {
    const response = await fetch(
      `markdown_docs?dir=${encodeURIComponent(dir)}&md_file_name=${md_file}`,
    );
    md = await response.json();
    // probes_name.set(probes);
    console.log("md=", md);
    return md
  }
  //console.log("markdown=", markdown);
  let markdown_name = $state("default");
  let { data, dir, md_file } = $props();
  // let md = $state("# Hello world\nThis is sample markdown.");
  let md = $derived(load_markdown(md_file,dir));
  let show_markdown = $state(false);
</script>
{#if data.props.markdown_files.length > 0}
  <button
    use:tooltip={() => msg("show or hide markdown")}
    onclick={() => (show_markdown = !show_markdown)}
    class="button-3"
    >show/hide markdown</button
  >
{/if}
<div style="border: 2px solid gold;"><Markdown {md} [gfmPlugin()]/></div>
{#if show_markdown}  
  <div><textarea bind:value={md}></textarea></div>
{/if}
<div>
  <button
    onclick={() => save_markdown(md, dir+md_file)}
    class="button-1"
    use:tooltip={() => msg("save markdown")}
  >
    Save markdown</button
  >  <button
    onclick={() => save_markdown(md, dir+md_file)}
    class="button-1"
    use:tooltip={() => msg("save markdown in a working directory")}
  >
    Save markdown as</button
  >
  <label>
    <input
      type="text"
      autocomplete="off"
      onkeydown={async (e) => {
        if (e.key == "Enter") {
          save_markdown(md, dir+md_file);
        }
      }}
      bind:value={markdown_name}
      style="border:darkgray solid 1px;"
    />
  </label>
  <!-- button
    onclick={() => load_markdown(md_file, data.props.wdir)}
    class="button-1"
    use:tooltip={() => msg("load markdown from a file")}
    >Load markdown
  </button -->
  </div>

<style>
</style>
