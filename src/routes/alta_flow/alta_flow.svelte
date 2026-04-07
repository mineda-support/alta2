<script lang="ts">
    import Markdown_docs from "../markdown_docs/markdown_docs.svelte";
    import { tooltip, msg } from "../Utils/tooltip.svelte";
    import EditModels from "../Utils/edit_models.svelte";
    import { proj, settings } from "../shared.svelte.js";
    import { switch_wdir } from "../openCircuit.svelte";
    // import { process_params } from "express/lib/router";
    import yaml from "js-yaml";
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
        return current_flow_step;
    }

    function create_flow_step(dir) {
        const current_flow_step = add_flow_step();
        proj.gap = '';
        if (dir != proj.dir) {
          proj.gap = dir.replace(proj.dir.replace(/\/$/, ''), '');  
        }

        let flow_step = {};
        flow_step.jobs = {};
        flow_step.jobs['transim'] = {};
        flow_step.jobs['transim']['steps'] = 
          [{ command: 'open', wdir: proj.dir, ckt: proj.gap + proj.file}]; 
        flow_settings.procedure[current_flow_step] = yaml.dump(flow_step);
    }

    function delete_flow_step() {
        console.log("current_flow_step to delete=", current_flow_step);
        for (const [obj] of Object.entries(flow_settings)) {
            if (Array.isArray(flow_settings[obj])) {
                flow_settings[obj].splice(current_flow_step, 1);
            }
        }
    }

    function clear_flow() {
        flow_settings = {
            flow_number: 0,
            showhide: [],
            title: [],
            procedure: [],
        };
        current_flow_step = 0;
    }

    async function save_flow_settings(flow_name) {
        const props = {};
        props.wdir = data.props.wdir + "FLOW/";
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

    function run_command(steps) {
        let encoded_params = "";
        for (const [name, value] of Object.entries(steps)) {
            encoded_params += `&${name}=${encodeURIComponent(value)}`;
            //console.log(`    ${name}: ${value}`);
        }
        console.log(`  encoded_params: ${encoded_params}`);
        window.location = "?show_flow=false" + encoded_params;
    }

    function execute_flow(flow_name) {
        // alert(`execute flow ${flow_name} with settings ${JSON.stringify(flow_settings)}`);
        flow_settings.procedure.forEach(function (p, i) {
            if (flow_settings.showhide[i]) {
                console.log(
                    `execute step ${i} with procedure ${flow_settings.procedure[i]}`,
                );
                let proc = yaml.load(p);
                console.log(proc);
                //Object.entries(proc.jobs).forEach(([job_name, job_config]) => {
                if (proc.jobs) {
                    for (const [job_name, job_config] of Object.entries(
                        proc.jobs,
                    )) {
                        console.log(
                            `execute job '${job_name}' with config ${JSON.stringify(job_config)}`,
                        );
                        job_config.steps.forEach((steps, i) => {
                            console.log(`  ${i}: ${steps}`);
                            if (steps.command) {
                                run_command(steps);
                            }
                        });
                        // Here you would add the logic to execute the job based on its configuration}}
                    }
                }
            }
        });
    }
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
            <button onclick={() => bsim3_step1()}>
                {flow_title} #{i + 1}
            </button>
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
        onclick={() => load_flow_settings(chosen, data.props.wdir + "FLOW/")}
        class="button-1"
        use:tooltip={() => msg("load flow settings from a working directory")}
    >
        Load flow</button
    >
    <button
        onclick={() => save_flow_settings(flow_title)}
        class="button-1"
        use:tooltip={() => msg("save flow settings in a working directory")}
    >
        Save flow</button
    >
    <button
        onclick={() => clear_flow(flow_title)}
        class="button-1"
        use:tooltip={() => msg("clear flow")}
    >
        Clear flow</button
    >
    <button
        onclick={() => execute_flow(flow_title)}
        class="button-1"
        use:tooltip={() => msg("execute flow settings in a working directory")}
    >
        Execute flow</button
    >
    <button
        onclick={() => create_flow_step(data.props.wdir)}
        class="button-1"
        use:tooltip={() => msg("create a new flow step from the current circuit settings")}
    >
        Create flow step</button
    >
</div>
