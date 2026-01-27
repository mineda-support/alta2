<script lang="ts">
    import Markdown_docs from "../markdown_docs/markdown_docs.svelte";
    import { tooltip, msg } from "../Utils/tooltip.svelte";
    import EditModels from "../Utils/edit_models.svelte";
    import { settings } from "../shared.svelte.js";
    import { switch_wdir } from "../openCircuit.svelte";
    import { process_params } from "express/lib/router";
    let {
        port,
        ckt_data = $bindable(),
        current_plot = $bindable(),
        data = $bindable(),
        show_flow = $bindable(),
        chosen = $bindable(),
    } = $props();

    let flow_settings = $state({
        flow_number: 0,
        showhide: [],
        title: [],
        procedure: [],
    });
    let current_flow_step = $state(0);
    let flow_title = $state("Bsim3 fitting");
    function add_flow_step() {
        flow_settings.showhide.push(true);
        console.log(
            "flow_settings.showhide=",
            $state.snapshot(flow_settings.showhide),
        );
        // console.log('length=', settings.plot_showhide.length);
        current_flow_step = flow_settings.showhide.length - 1;
        console.log(
            "flow_settings.showhide=",
            $state.snapshot(flow_settings.showhide),
            "current_flow_step=",
            $state.snapshot(current_flow_step),
        );
    }

    function delete_flow_step() {
        console.log("current_flow_step to delete=", current_flow_step);
        for (const [obj] of Object.entries(flow_settings)) {
            if (Array.isArray(flow_settings[obj])) {
                flow_settings[obj].splice(current_flow_step, 1);
            }
        }
    }

    async function save_flow_settings(flow_name) {
        const props = {};
        props.wdir = data.props.wdir + 'FLOW/';
        props.flow_name = flow_name;
        props.flow_settings = flow_settings;
        const response = await fetch("alta_flow", {
            method: "POST",
            body: JSON.stringify(props),
            headers: {
                "Content-Type": "application/json",
            },
        });
        flow_names = await response.json();
        console.log("flow names:", flow_names);
        if (flow_names.includes(flow_name)) {
            alert(`${flow_name} saved`);
        }
    }

    async function load_flow_settings(flow_name, dir) {
        const response = await fetch(
            `alta_flow?dir=${encodeURIComponent(dir)}&flow_name=${flow_name}`,
        );
        // const result = await response.json();
        let props = await response.json();
        //[flow_title, flow_settings] = props;
        flow_title = props.flow_title;
        flow_settings = props.flow_settings;

        // probes_name.set(probes);
        console.log("props=", props);
    }
    //console.log("settings=", settings);
    let flow_name = $state("default");
    let flow_names = $state(data.props.flow_names);
    let show_readme = $derived(data.props.markdown_files.includes("README.md"));
</script>

<p>
    Flow directory:
    {#if data != undefined && data.props != undefined && data.props.wdir != undefined}
        <input
            bind:value={data.props.wdir}
            style="border:darkgray solid 1px;width: 50%;"
        />
    {/if}
    <button
        use:tooltip={() => msg("switch working directory")}
        onclick={handle_switch_wdir}
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
        <Markdown_docs
            {data}
            dir={data.props.wdir}
            md_file={"FLOW/README.md"}
        />
    {/if}
    <div class="sample">
        {#each flow_names as file}
            <label class="box-item" style="background:lightblue;">
                <input
                    type="radio"
                    name="chosen"
                    value={file}
                    bind:group={chosen}
                />
                {file}<br />
            </label>
        {/each}
    </div>
{/if}
<!-- div>
    <button
        onclick={() => read_json(data.props.port, data.props.wdir, chosen)}
        class="button-1"
        use:tooltip={() => msg("readin circuit checked above")}
    >
        Click here to read JSON file</button
    >
</div -->
<Markdown_docs
    {data}
    dir={data.props.wdir}
    md_file={"FLOW/Documents/" + chosen + ".md"}
/>
<label use:tooltip={() => msg("Flow title")}
    >Flow_title:
    <input bind:value={flow_title} style="border:darkgray solid 1px;" />
</label>

{#each flow_settings.showhide as _, i}
    <div>
        <label use:tooltip={() => msg("procedures in Step")}>
            <button onclick={() => bsim3_step1()}> {flow_title} #{i + 1} </button>
            <textarea
                bind:value={flow_settings.procedure[i]}
                style="border:darkgray solid 1px; width: 50%; height: 20px; text-align: bottom"
            />
        </label>
    </div>
{/each}

<button
    use:tooltip={() => msg("add a flow step")}
    onclick={add_flow_step}
    class="button-2">Add flow step</button
>
<button
    use:tooltip={() => msg("delete this flow step")}
    onclick={delete_flow_step}
    class="button-2">Delete flow step</button
>
<div>
    <button
        onclick={() => save_flow_settings(flow_title)}
        class="button-1"
        use:tooltip={() => msg("save flow settings in a working directory")}
    >
        Save flow</button
    >
</div>
