<script module>
    export async function update_elements(dir, ckt, elements) {
        for (const [ckt_name, elms] of Object.entries(ckt.elements)) {
            if (ckt_name[0] == ".") {
                continue;
            }
            let target = ckt_name + ".asc";
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
                    )}&file=${encodeURIComponent(file)}&probes=${encodeURIComponent(
                    probes,
                    )}`;

                const command = `http://localhost:${port}/api/ltspctl/update?${encoded_params}&updates=${update_elms}`;
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
                let target = ckt_name + ".asc";
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
    import { get_control } from "./openLTspice.svelte";
    import { proj, ckt } from "./shared.svelte";

    export async function goLTspice() {
        if (ckt == undefined) {
            alert("Please read-in the circuit before simulation");
            return;
        }
        console.log(`openLTspice dir='${proj.dir}' file='${proj.file}'`);
        //dispatch("elm_update", { text: "Update elements" });
        update_elements(prj.dir, ckt, proj.elements);
        //const my_sleep = (ms) =>
        //    new Promise((resolve) => setTimeout(resolve, ms));
        //await my_sleep(3000);
        console.log('variations', $state.snapshot(variations));
        let encoded_params = `proj.dir=${encodeURIComponent(
            proj.dir,
        )}&file=${encodeURIComponent(
            proj.file,
        )}&variations=${encodeURIComponent(JSON.stringify(variations))}`;
        const models_update = update_models(ckt, proj.models);
        if (models_update != {}) {
            encoded_params =
                encoded_params +
                `&models_update=${encodeURIComponent(JSON.stringify(models_update))}`;
        }
        // dispatch("sim_start", { text: "LTspice simulation started!" });
        on_sim_start("LTspice simulation started!");
        let response = await fetch(
            `http://localhost:${port}/api/ltspctl/simulate?${encoded_params}`,
            {},
        );
        let res2 = await response.json();
        console.log(res2);
        //if (ckt.info == null) {
        response = await fetch(
            `http://localhost:${port}/api/ltspctl/info?${encoded_params}`,
            {},
        );
        res2 = await response.json();
        ckt.info = res2.info;
        // console.log(ckt.info);
        // ckt_store.set(ckt);
        //}
        on_sim_end("LTspice simulation ended!");
        
        // plotdata = get_results();
        return res2;
    }
    let { variations = $bindable(), probes = $bindable() , on_sim_start, on_sim_end } = $props();
</script>

<button onclick={goLTspice} class="button-1">
    Click here to Start LTspice simulation</button
>

<style>
</style>
