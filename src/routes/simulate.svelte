<script module>
    export async function update_elements(port, dir, ckt, elements, probes, schema_editor) {
        for (const [ckt_name, elms] of Object.entries(ckt.elements)) {
            if (ckt_name[0] == ".") {
                continue;
            }
            let target;
            switch(schema_editor){
                case 'LTspice':
                    target = ckt_name + ".asc";
                    break;
                case 'Xschem':
                    target = ckt_name + ".sch";
                    break;
                case 'EEschema':
                    target = ckt_name + ".sch";
                    break;
                }
            console.log('target=', target)
            console.log(
                "update elements=",
                $state.snapshot(elements),
                ` here @ dir= ${dir} file=${target}`,
            );
            let update_elms = "";
            for (const [elm, props] of Object.entries(elms)) {
                if (elements[ckt_name][elm] != get_control(props)) {
                    update_elms =
                        update_elms +
                        elm +
                        ":'" +
                        elements[ckt_name][elm] +
                        "',";
                }
            }
            if (update_elms != "") {
                console.log("let me update ", target, " with:", update_elms);
                update_elms = encodeURIComponent(`{${update_elms}}`);

                let encoded_params = `dir=${encodeURIComponent(
                    dir,
                )}&file=${encodeURIComponent(target)}`;

                if (probes != undefined) {
                  encoded_params = encoded_params + `&probes=${encodeURIComponent(
                      probes,
                  )}`;
                };

                const command = `http://localhost:${port}/api/${proj.ctl_type}/update?${encoded_params}&updates=${update_elms}`;
                console.log(command);
                let response = await fetch(command, {});
                let ckt = await response.json(); // ckt = {elements}
                console.log("ckt=", ckt);
                for (const [elm, props] of Object.entries(ckt.elements)) {
                    if (elements[ckt_name][elm] != get_control(props)) {
                        console.log(
                            `Update error! ${elm}: ${get_control(props)}vs.${
                                elements[ckt_name][elm]
                            }`,
                        );
                    }
                }
            }
        }
        // ckt_store.set(ckt);
        // elements_store.set(elements);
    }

    export function update_models(ckt, models) {
        let update_mdls = {};
        for (const [model_name, model_params] of Object.entries(ckt.models)) {
            for (const [par, value] of Object.entries(model_params[1])) {
                if (models[model_name][par] != value) {
                    update_mdls[model_name] ||= {};
                    update_mdls[model_name][par] = models[model_name][par];
                }
            }
            if (update_mdls[model_name] != undefined) {
                console.log(
                    "let me update model_name=",
                    model_name,
                    "with:",
                    update_mdls[model_name],
                );
                //update_mdls = encodeURIComponent(`{${update_mdls}}`);
            }
        }
        return update_mdls;
    }
</script>

<script lang="ts">
    import { get_control, ctl_info } from "./openCircuit.svelte";
    import { proj, ckt } from "./shared.svelte";
    import { tooltip, msg } from "./Utils/tooltip.svelte";
    export async function goLTspice() {
        console.log('ckt=', $state.snapshot(ckt));
        if (ckt == undefined) {
            alert("Please read-in the circuit before simulation");
            return;
        }
        console.log(`openCircuit dir='${proj.dir}' file='${proj.file}'`);
        //dispatch("elm_update", { text: "Update elements" });
        update_elements(port, proj.dir, ckt, proj.elements, probes, proj.schema_editor);
        const my_sleep = (ms) =>
        new Promise((resolve) => setTimeout(resolve, ms));
        await my_sleep(500);
        console.log("variations", $state.snapshot(variations));
        let encoded_params = `dir=${encodeURIComponent(
            proj.dir,
        )}&file=${encodeURIComponent(
            proj.file,
        )}&probes=${encodeURIComponent(
                probes,
        )}&variations=${encodeURIComponent(JSON.stringify(variations))}`;
        
        const models_update = update_models(ckt, proj.models);
        if (models_update != {}) {
            encoded_params =
                encoded_params +
                `&models_update=${encodeURIComponent(JSON.stringify(models_update))}`;
        }
        // dispatch("sim_start", { text: "LTspice simulation started!" });
        on_sim_start("Simulation started!");
        let response = await fetch(
            `http://localhost:${port}/api/${proj.ctl_type}/simulate?${encoded_params}`,
            {},
        );
        let res2 = await response.json();
        console.log(res2);
        //if (ckt.info == null) {
        response = await fetch(
            `http://localhost:${port}/api/${proj.ctl_type}/info?${encoded_params}`,
            {},
        );
        res2 = await response.json();
        ckt.info = ctl_info(res2.info, proj);
        console.log($state.snapshot(ckt.info));
        // ckt_store.set(ckt);
        //}
        on_sim_end("Simulation ended!");

        // plotdata = get_results();
        return res2;
    }
    let {
        port,
        variations = $bindable(),
        probes = $bindable(),
        on_sim_start,
        on_sim_end,
    } = $props();
</script>

<button
    onclick={goLTspice}
    class="button-1"
    use:tooltip={() => msg("run simulation")}
>
    Click here to start {proj.simulator} simulation</button
>
