<script module>
  // import { goto } from "$app/navigation";
  export function get_control(props) {
    if (Array.isArray(props)) {
      return props[0].control || "*" + props[0].comment;
    } else {
      return props.value;
    }
  }

  export function switch_wdir(wdir, show_flow) {
    /* if (wdir == undefined) {
      const handle = await window.showDirectoryPicker();
      wdir = handle.name; //USELESS because does not return PATH
    } */
    console.log("wdir=", wdir);
    //goto("?wdir=" + wdir.replace(/^"/, "").replace(/"$/, ""));
    window.location =
      "?show_flow=" +
      show_flow +
      "&wdir=" +
      wdir.replace(/^"/, "").replace(/"$/, "");
  }
</script>

<script lang="ts">
  import Markdown_docs from "./markdown_docs/markdown_docs.svelte";
  import { edif2ltspice } from "./convertSchematic.svelte";
  import { tooltip, msg } from "./Utils/tooltip.svelte";
  import InputWideValue from "./Utils/input_wide_value.svelte";
  import EditModels from "./Utils/edit_models.svelte";
  import { info_translated } from "./simulate.svelte";
  function set_ctl_type(file) {
    if (file.match(/\.asc/)) {
      console.log(`${file} type is ltspice`);
      proj.ctl_type = "ltspctl";
      proj.simulator = "LTspice";
      proj.schema_editor = "LTspice";
    } else if (file.match(/\.sch/)) {
      console.log(`${file} type is ngspice`);
      proj.ctl_type = "ngspctl";
      proj.simulator = "Ngspice";
      proj.schema_editor = "Xschem";
    }
  }
  async function openCircuit(port, dir, file, showup) {
    if (file == undefined) {
      alert("Please choose the circuit to open");
      return;
    }
    if (file.match(/\.edif/)) {
      if (!alert(`Convert ${file} to LTspice schematic`)) {
        edif2ltspice(port, dir, file);
        return;
      }
    }
    proj.file = file;
    set_ctl_type(file);
    proj.dir = dir;
    console.log(`openCircuit port=${port} dir='${dir}' file='${file}'`);
    let encoded_params;
    if (showup) {
      encoded_params = `dir=${encodeURIComponent(
        dir,
      )}&file=${encodeURIComponent(file)}&showup=true`;
    } else {
      encoded_params = `dir=${encodeURIComponent(
        dir,
      )}&file=${encodeURIComponent(file)}`;
    }
    console.log(encoded_params);
    let response = await fetch(
      `http://localhost:${port}/api/${proj.ctl_type}/open?${encoded_params}`,
      {},
    );
    let res2 = await response.json();
    console.log(res2);
    if (res2.error) {
      alert(res2.error);
      return;
    }
    console.log("probes:", probes);
    if (probes != undefined) {
      // goLTspice();
      // plot_result();
      // dispatch("open_end", { text: "fake simulation ended!" });
    }
    ckt.elements = res2.elements;
    ckt.models = res2.models;
    ckt.info = info_translated(res2.info, proj);
    //console.log("ckt=", $inspect(ckt));
    if (ckt != undefined) {
      proj.elements = {};
      for (const [ckt_name, elms] of Object.entries(ckt.elements)) {
        //console.log(ckt_name, "=", elms);
        if (ckt_name[0] == ".") {
          console.log("skip:", ckt_name);
          continue;
        }
        proj.elements[ckt_name] = {};
        for (const [elm, props] of Object.entries(elms)) {
          // console.log([elm, props]);
          if (Array.isArray(props)) {
            if (Object.values(props).length == 1) {
              proj.elements[ckt_name][elm] = props[0].control;
            } else {
              Object.values(props).forEach(function (p, index) {
                proj.elements[ckt_name][elm + String(index + 1)] = p.control;
              });
            }
          } else {
            proj.elements[ckt_name][elm] = props.value;
          }
        }
      }
      console.log("elements=", $state.snapshot(proj.elements));
      proj.models = {};
      for (const [model_name, model_params] of Object.entries(ckt.models)) {
        if (model_name.match(/Error/)) {
          alert(model_name);
        } else {
          proj.models[model_name] = {};
          for (const [par, value] of Object.entries(model_params[1])) {
            proj.models[model_name][par] = value;
          }
        }
      }
      console.log("models=", $state.snapshot(proj.models));
      if (Object.keys(ckt.models).length == 0) {
        alert("Warning: SPICE models are not included in the circuit");
      }
    }
    alter = [{}];
    alter_src = undefined;
    nvar = 0;
    current_plot = 0;
    return res2;
  }

  let {
    data = $bindable(),
    probes = $bindable(),
    variations = $bindable({}),
    nvar = $bindable(),
    current_plot = $bindable(),
    chosen = $bindable(),
  } = $props();
  import { proj, ckt } from "./shared.svelte";
  import { disableScrollHandling } from "$app/navigation";
  //import { files } from "$service-worker"; ### this caused app.js:16 ReferenceError: ServiceWorkerGlobalScope is not defined
  //import { esbuildVersion } from "vite";

  // let chosen = $state(data.props.ckt);
  let showup = $state(false);
  if (chosen != undefined) {
    openCircuit(data.props.port, data.props.wdir, chosen, showup);
  }

  let alter_src = $state();
  let alter = $state([{}]);

  function add_alter() {}

  function check_alter() {
    console.log("alter=", alter);
  }

  function add_variation_item(src) {
    //console.log('src in add_variation_item=', src);
    if (src == null) {
      alert("Please select elements to variate");
      return;
    }
    if (variations[src] == undefined) {
      variations[src] = [];
      if (nvar == 0) {
        add_variation_value(src);
        nvar = 1;
      } else {
        for (let i = 0; i < nvar; i = i + 1) {
          add_variation_value(src);
        }
      }
    }
    variations = variations;
    console.log("variations=", variations);
  }

  function add_variation_value(src) {
    let ckt_name, elm;
    [ckt_name, elm] = src.split(":");
    //let new_elm = JSON.parse(JSON.stringify(elements[ckt_name][elm]));
    const new_elm = proj.elements[ckt_name][elm];
    console.log(`push elements[${ckt_name}][${elm}]=`, new_elm);
    variations[src].push(new_elm);
    console.log("variations=", variations);
  }

  function remove_variation_item(src) {
    console.log(`remove ${src} from:`, variations);
    const result = delete variations[src];
    console.log(`remove result=${result}:`, variations);
    variations = variations;
  }

  function add_variation() {
    console.log("variations=", variations);
    for (const [key, values] of Object.entries(variations)) {
      add_variation_value(key);
    }
    nvar = nvar + 1;
    console.log("variation added:", variations, "nvar=", nvar);
    variations = variations;
  }

  function remove_variation(index) {
    //console.log("Before: ", variations, 'nvar=', nvar);
    //alert(`remove_variation clicked!@index=${index}`);
    for (const [key, values] of Object.entries(variations)) {
      console.log("remove values=", values, "from:", key);
      if (values.length > 1) {
        values.splice(index, 1);
      }
    }
    nvar = nvar - 1;
    //console.log("After: ", variations, 'nvar=', nvar);
    variations = variations;
  }

  let src = $state();
  // let nvar = 0;
  let remove_index = $state(0);
  if (data != undefined && data.props != undefined) {
    proj.dir = data.props.wdir;
    console.log("*** dir=", proj.dir);
  }
  let show_symbol_files = $state(false);
  let show_markdown_files = $state(false);
  //t show_readme = $state(false);   let md = $derived(load_markdown(md_file, dir));
  let show_readme = $derived(data.props.markdown_files.includes("README.md"));
  let filter = $state("");
</script>

<p>
  Work directory:
  {#if data != undefined && data.props != undefined && data.props.wdir != undefined}
    <input
      bind:value={data.props.wdir}
      style="border:darkgray solid 1px;width: 50%;"
    />
  {/if}
  <!-- input bind:value={content} / -->

  <button
    use:tooltip={() => msg("switch working directory")}
    onclick={() => switch_wdir(data.props.wdir, false)}
    class="button-1">Switch Wdir</button
  >
</p>
{#if data.props != undefined}
  <button
    use:tooltip={() => msg("show or hide README.md")}
    onclick={() => (show_readme = !show_readme)}
    class="button-3">show/hide README</button
  >
  {#if show_readme}
    <Markdown_docs {data} dir={data.props.wdir} md_file={"README.md"} />
  {/if}

  <div class="sample">
    {#each [".."].concat(data.props.sub_directories) as subdir}
      <button
        use:tooltip={() => msg("select directory to switch")}
        onclick={() => switch_wdir(data.props.wdir + subdir, false)}
        class="box-item2">{subdir}</button
      >
    {/each}
    {#each data.props.files as file}
      <label class="box-item">
        <input type="radio" name="chosen" value={file} bind:group={chosen} />
        {file}<br />
      </label>
    {/each}
  </div>
  <Markdown_docs
    {data}
    dir={data.props.wdir}
    md_file={"Documents/" + chosen + ".md"}
  />
  {#if data.props.symbol_files.length > 0}
    <button
      use:tooltip={() => msg("show or hide symbol files")}
      onclick={() => (show_symbol_files = !show_symbol_files)}
      class="button-3">show/hide symbols</button
    >
  {/if}
  {#if show_symbol_files}
    <div class="sample">
      {#each data.props.symbol_files as file}
        <label class="box-item">
          {file}<br />
        </label>
      {/each}
    </div>
  {/if}
{/if}
{#if data.props.markdown_files.length > 0}
  <button
    use:tooltip={() => msg("show or hide markdown document files")}
    onclick={() => (show_markdown_files = !show_markdown_files)}
    class="button-3">show/hide documents</button
  >
{/if}
{#if show_markdown_files}
  <div class="sample">
    {#each data.props.markdown_files as file}
      <label class="box-item3">
        <input type="radio" name="chosen" value={file} bind:group={chosen} />
        {file}<br />
      </label>
    {/each}
  </div>
  <Markdown_docs {data} dir={data.props.wdir} md_file={chosen} />
{/if}
<hr />
<div>
  <button
    onclick={() =>
      openCircuit(data.props.port, data.props.wdir, chosen, showup)}
    class="button-1"
    use:tooltip={() => msg("readin circuit checked above")}
  >
    Click here to read-in</button
  >
  <label use:tooltip={() => msg("show up schematic editor")}>
    <input type="checkbox" bind:checked={showup} />
    show schematic
  </label>
</div>

<!-- div style="border:red solid 2px;">
    {#each Object.entries(ckt.elements) as [elm, props]}
      <div>{elm}:{get_control(props)}({elements[elm]})</div>
    {/each}
  </div -->

{#if proj.file != undefined}
  <div class="tab-wrap">
    <input
      id="TAB-01"
      type="radio"
      name="TAB"
      class="tab-switch"
      checked="checked"
    />
    <label
      class="tab-label"
      for="TAB-01"
      use:tooltip={() => msg("elements and control")}
    >
      Circuit info</label
    >
    <div class="tab-content" style="border:red solid 2px;">
      {#if ckt != undefined}
        {#each Object.entries(proj.elements) as [ckt_name, elms]}
          [{ckt_name}]<br />
          {#each Object.entries(elms) as [elm]}
            <label
              >{elm}:
              <input
                style="border:darkgray solid 1px;"
                bind:value={proj.elements[ckt_name][elm]}
              /><br /></label
            >
          {/each}
        {/each}
      {/if}
    </div>
    <input id="TAB-02" type="radio" name="TAB" class="tab-switch" />
    <label class="tab-label" for="TAB-02">SPICE models</label>
    <EditModels bind:models={proj.models} {filter} />
    <input id="TAB-03" type="radio" name="TAB" class="tab-switch" />
    <label class="tab-label" for="TAB-03">Alter</label>
    <div class="tab-content" style="border:blue solid 2px;">
      <div>Add Alter</div>
      <select bind:value={alter_src} style="border:darkgray solid 1px;">
        {#each Object.entries(proj.elements) as [ckt_name, elms]}
          {#each Object.keys(elms) as elm}
            <option value={[ckt_name, elm].join(":")}
              >{[ckt_name, elm].join(":")}</option
            >
          {/each}
        {/each}
      </select>
      <input
        style="border:darkgray solid 1px;"
        bind:value={alter[0][alter_src]}
      /><br />
      <button onclick={add_alter} class="button-item">New Tab</button>
      <button onclick={check_alter} class="button-item">Check Alter</button>
    </div>
    <input id="TAB-04" type="radio" name="TAB" class="tab-switch" />
    <label
      class="tab-label"
      for="TAB-04"
      use:tooltip={() => msg("variations on device parameters")}
    >
      Variation</label
    >
    <div class="tab-content" style="border:yellow solid 2px;">
      <div>
        Add Variation
        <select bind:value={src} style="border:darkgray solid 1px;">
          {#each Object.entries(proj.elements) as [ckt_name, elms]}
            {#each Object.keys(elms) as elm}
              <option value={[ckt_name, elm].join(":")}
                >{[ckt_name, elm].join(":")}</option
              >
            {/each}
          {/each}
        </select>
        <button onclick={() => add_variation_item(src)} class="td-button"
          >+</button
        >
        <button onclick={() => remove_variation_item(src)} class="td-button"
          >-</button
        >
        (nvar={nvar})
      </div>
      <table>
        <thead>
          <tr
            ><th>Name</th>
            {#each Object.entries(variations) as [elm, vals]}
              <th>{elm}</th>
            {/each}
          </tr>
        </thead>
        <tbody>
          {#if nvar > 0}
            {#each Array(nvar) as _, i}
              <tr>
                <td>
                  {i}
                  <!--button on:click={remove_variation(i)} class="td-button"
                  >-</button
                -->
                </td>
                {#each Object.entries(variations) as [elm, vals]}
                  <td
                    ><InputWideValue
                      lab={elm + "#" + String(i + 1)}
                      bind:val={vals[i]}
                    />
                  </td>
                {/each}
              </tr>
            {/each}
          {/if}
          <tr>
            <td><button onclick={add_variation} class="td-button">+</button></td
            >

            <td
              ><button
                onclick={() => remove_variation(remove_index)}
                class="td-button">-</button
              ></td
            >
            <td>remove_index:</td> <td><input bind:value={remove_index} /></td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
{/if}

<!--
{#if ckt != undefined}
[Probes list (clicked probe will be put in probes for a current plot)]
  <div class="sample">
    {#each ckt.info as node}
      <button 
      use:tooltip={()=>msg("push probe in probes for a current plot")}
      onclick={() => push_button(node)} class="button-item"
        >{node}</button
      >
    {/each}
  </div>
{/if}
-->
<style>
</style>
