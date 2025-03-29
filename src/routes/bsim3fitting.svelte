<script lang="ts">
    import { tooltip, msg } from "./Utils/tooltip.svelte";
    import EditModels from "./Utils/edit_models.svelte";
    import { settings } from "./shared.svelte.js";
    import { switch_wdir } from "./openCircuit.svelte";
    let {
        port,
        ckt_data = $bindable(),
        current_plot = $bindable(),
        data = $bindable(),
        show_flow = $bindable(),
    } = $props();
    async function bsim3_step1() {
        // console.log("ckt_data.plotdata=", $state.snapshot(ckt_data.plotdata));
        //alert("bsim3 step1");
        console.log(`procedure to send: ${procedure}`);
        console.log(
            "plotdata:",
            $state.snapshot(ckt_data.plotdata[current_plot]),
        );
        console.log("settings:", $state.snapshot(settings));
        const res = await fetch(`http://localhost:${port}/api/misc/exec_proc`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                model: filename
                    .trim()
                    .replace(/\\/g, "/")
                    .replace(/^"/, "")
                    .replace(/"$/, ""),
                procedure: procedure,
                settings: settings,
                jtable: {
                    measdata: ckt_data.plotdata[current_plot]
                        ? ckt_data.plotdata[current_plot].concat(
                              ckt_data.measdata[current_plot],
                          )
                        : [],
                },
            }),
        });
        let result = await res.json();
        let plot_data = await result.plot_data;
        return plot_data;
    }
    let bsim3_models = $state({});
    let bsim3_models_org = $state({});

    export async function get_models(port, filename) {
        if (filename == undefined) {
            alert("Please set file path");
            return;
        }
        let encoded_params = `file=${encodeURIComponent(filename.trim().replace(/^"/, "").replace(/"$/, ""))}`;
        let response = await fetch(
            `http://localhost:${port}/api/misc/get_models?${encoded_params}`,
            {},
        );
        let res2 = await response.json();
        bsim3_models = {};
        for (const [model_name, model_params] of Object.entries(res2.models)) {
            bsim3_models[model_name] = {};
            for (const [par, value] of Object.entries(model_params[1])) {
                bsim3_models[model_name][par] = value;
            }
        }
        console.log("bsim3_models=", $state.snapshot(bsim3_models));
        return bsim3_models; // returned value not used
    }

    export async function read_json(port, dir, file) {
        let encoded_params = `dir=${encodeURIComponent(
            dir,
        )}&file=${encodeURIComponent(file)}`;
        let response = await fetch(
            `http://localhost:${port}/api/misc/get_models?${encoded_params}`,
            {},
        );
        let res = await response.json();
        let settings;
        let plotdata;
        [settings, plotdata] = res.json;
    }
    let filename;
    let model_org;
    let filter = $state("");
    let procedure = $state(
        "calculate_vth_vbs_relation\n" + "estimate_vth_k1_k2\n",
    );
    function handle_switch_wdir() {
        show_flow = true;
        switch_wdir(data.props.wdir, true);
    }
    let chosen;
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
    <div class="sample">
        {#each data.props.files as file}
            <label class="box-item" style="background:lightblue;">
                <input type="radio" name="chosen" value={file} />
                {file}<br />
            </label>
        {/each}
    </div>
{/if}
<div>
    <button
        onclick={() => read_json(data.props.port, data.props.wdir, chosen)}
        class="button-1"
        use:tooltip={() => msg("readin circuit checked above")}
    >
        Click here to read JSON file</button
    >
</div>
<div>
    BSIM3 model parameter fitting {#if ckt_data.plotdata[current_plot]}
        for {ckt_data.plotdata[current_plot].length} traces{/if}
</div>
<button
    use:tooltip={() => msg("Get models from a file")}
    onclick={() => (bsim3_models = get_models(port, filename))}
    class="button-1">Get models from file:</button
>
<input bind:value={filename} style="border:darkgray solid 1px;" />
<div>
    <label use:tooltip={() => msg("original model file (read only)")}
        >model_org
        <input bind:value={model_org} style="border:darkgray solid 1px;" />
    </label>
</div>
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
        use:tooltip={() => msg("flow conditions")}
    >
        Conditions</label
    >
    <div class="tab-content" style="border:red solid 2px;">
        <table>
            <thead>
                <tr>
                    {#each ["name", "vbs", "vgs", "vds", "vth", "l", "w"] as p}
                        <th>{p}</th>
                    {/each}
                </tr>
            </thead>
            <tbody>
                {#each ckt_data.plotdata[current_plot] as trace}
                    <tr>
                        {#each ["name", "vbs", "vgs", "vds", "vth", "l", "w"] as p}
                            <td
                                ><input
                                    style="border:darkgray solid 1px; width: 70%"
                                    bind:value={trace[p]}
                                /></td
                            >
                        {/each}
                    </tr>
                {/each}
            </tbody>
        </table>
    </div>
    <input id="TAB-02" type="radio" name="TAB" class="tab-switch" />
    <label class="tab-label" for="TAB-02">SPICE models</label>

    <EditModels bind:models={bsim3_models} {filter} />
</div>

<div>
    <label use:tooltip={() => msg("procedures in Step1")}
        >Step1 procedure
        <button onclick={() => bsim3_step1()}> BSIM3 Step1 </button>
        <textarea
            bind:value={procedure}
            style="border:darkgray solid 1px; width: 50%; height: 20px; text-align: bottom"
        />
    </label>
</div>
