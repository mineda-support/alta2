<script lang="ts">
  import Markdown from "svelte-exmarkdown";
  import { gfmPlugin } from "svelte-exmarkdown/gfm";
  import { tooltip, msg } from "../Utils/tooltip.svelte";
  async function save_markdown(md, md_file) {
    const props = {};

    const lines = md.split("\n");
    lines.forEach(function (line, index) {
      console.log(`${index}: ${line}`);
      const ret = line.match(new RegExp(`^ *!\\[.*\\(\(${username}\\/.*\)\\)`));
      if (ret) {
        line = line.replace(ret[1], ret[1].replace(`${username}/`, ''));
        console.log("replaced:", line);
        lines.splice(index, 1, line);
      }
    });
    md = lines.join("\n");

    props.md_data = md;
    props.md_file = md_file;
    const response = await fetch("markdown_docs", {
      method: "POST",
      body: JSON.stringify(props),
      headers: {
        "Content-Type": "application/json",
      },
    });
    show_markdown = false;
  }

  async function load_markdown(md_file, dir) {
    console.log("md_file=", md_file, "dir=", dir);
    if (md_file.includes("undefined")) return "";
    const response = await fetch(
      `markdown_docs?dir=${encodeURIComponent(dir)}&md_file_name=${md_file}`,
    );
    md = await response.json();
    // probes_name.set(probes);
    // console.log("md=", md);
    const lines = md.split("\n");
    lines.forEach(function (line, index) {
      console.log(`${index}: ${line}`);
      const ret = line.match(/^ *!\[.*\((.*)\)/);
      if (ret) {
        line = line.replace(ret[1], username + "/" + ret[1]);
        console.log("replaced:", line);
        lines.splice(index, 1, line);
      }
    });
    md = lines.join("\n");
    return md;
  }
  //console.log("markdown=", markdown);
  let markdown_name = $state("default");
  let { data, dir, md_file } = $props();
  let username = data.props.username;
  // let md = $state("# Hello world\nThis is sample markdown.");
  let md = $derived(load_markdown(md_file, dir));
  let show_markdown = $state(false);
</script>

<div style="border: 2px solid gold;"><Markdown {md} [gfmPlugin()] /></div>

<button
  use:tooltip={() => msg("show or hide markdown source")}
  onclick={() => (show_markdown = !show_markdown)}
  class="button-3">show/hide markdown source</button
>

{#if show_markdown}
  <div><textarea bind:value={md}></textarea></div>
  <div>
    <button
      onclick={() => save_markdown(md, dir + md_file)}
      class="button-1"
      use:tooltip={() => msg("save markdown")}
    >
      Save markdown</button
    >
    <!-- button
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
  </label -->
    <!-- button
    onclick={() => load_markdown(md_file, data.props.wdir)}
    class="button-1"
    use:tooltip={() => msg("load markdown from a file")}
    >Load markdown
  </button -->
  </div>
{/if}

<style>
</style>
