<script lang="ts">
  import { settings } from "../shared.svelte.js";
  import { tooltip, msg } from "../Utils/tooltip.svelte";
  async function save_settings(settings_name) {
    const props = {};
    props.home = data.props.home;
    props.wdir = data.props.wdir;
    props.settings_name = settings_name;
    props.ckt = ckt;
    props.variations = variations;
    console.log("settings=", $state.snapshot(settings));
    props.settings = {};
    for (const [item, value] of Object.entries(settings)) {
      props.settings[item] = value;
    }
    console.log("props=", props);
    const response = await fetch("settings", {
      method: "POST",
      body: JSON.stringify(props),
      headers: {
        "Content-Type": "application/json",
      },
    });
    const setting_names = await response.json();
    console.log("setting names:", setting_names);
    if (setting_names.includes(settings_name)) {
      alert(`${settings_name} saved`);
      data.props.setting_names = setting_names;
    }
  }

  async function load_settings(settings_name, dir) {
    const response = await fetch(
      `settings?dir=${encodeURIComponent(dir)}&settings_name=${settings_name}`,
    );
    // const result = await response.json();
    const props = await response.json();
    // probes_name.set(probes);
    console.log("props=", props);
    // settings = {};
    //settings = props.settings;
    for (const [k, v] of Object.entries(props.settings)) {
      settings[k] = v;
    }
    variations = props.variations;
  }
  //console.log("settings=", settings);
  let settings_name = $state("default");
  let { data, ckt, variations = $bindable() } = $props();
</script>

<div>
  <button
    onclick={() => save_settings(settings_name)}
    class="button-1"
    use:tooltip={() => msg("save settings in a working directory")}
  >
    Save settings in:</button
  >
  <label>
    <input
      type="text"
      autocomplete="off"
      onkeydown={async (e) => {
        if (e.key == "Enter") {
          save_settings(settings_name);
        }
      }}
      bind:value={settings_name}
      style="border:darkgray solid 1px;"
    />
  </label>
  <button
    onclick={() => load_settings(settings_name, data.props.wdir)}
    class="button-1"
    use:tooltip={() => msg("load settings from a file")}
    >Load settings from:
  </button>
  <select
    bind:value={settings_name}
    style="border:darkgray solid 1px;"
    onchange={() => load_settings(settings_name, data.props.wdir)}
  >
    {#if data.props != undefined}
      {#each data.props.setting_names as setting}
        <option value={setting}>{setting}</option>
      {/each}
    {/if}
  </select>
</div>

<style>
</style>
