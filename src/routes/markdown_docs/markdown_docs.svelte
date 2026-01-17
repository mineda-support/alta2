<script lang="ts">
  import Markdown from 'svelte-exmarkdown';
  import { tooltip, msg } from "../Utils/tooltip.svelte";
  async function save_markdown(md_file) {
    const props = {};
    props.home = data.props.home;
    props.wdir = data.props.wdir;
    props.markdown_name = markdown_name;
    props.ckt = ckt;
    props.variations = variations;
    console.log("markdown=", $state.snapshot(markdown));
    props.markdown = {};
    for (const [item, value] of Object.entries(markdown)) {
      props.markdown[item] = value;
    }
    console.log("props=", props);
    const response = await fetch("markdown", {
      method: "POST",
      body: JSON.stringify(props),
      headers: {
        "Content-Type": "application/json",
      },
    });
    const setting_names = await response.json();
    console.log("setting names:", setting_names);
    if (setting_names.includes(markdown_name)) {
      alert(`${markdown_name} saved`);
      data.props.setting_names = setting_names;
    }
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
</script>

<div>
  <button
    onclick={() => save_markdown(markdown_name)}
    class="button-1"
    use:tooltip={() => msg("save markdown in a working directory")}
  >
    Save markdown in:</button
  >
  <label>
    <input
      type="text"
      autocomplete="off"
      onkeydown={async (e) => {
        if (e.key == "Enter") {
          save_markdown(markdown_name);
        }
      }}
      bind:value={markdown_name}
      style="border:darkgray solid 1px;"
    />
  </label>
  <button
    onclick={() => load_markdown(md_file, data.props.wdir)}
    class="button-1"
    use:tooltip={() => msg("load markdown from a file")}
    >Load markdown
  </button>
  <hr />
  <textarea bind:value={md}></textarea>
  <Markdown {md} />
</div>

<style>
</style>
