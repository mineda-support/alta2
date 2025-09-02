<script module>
    export function schema_file(ckt_name, schema_editor) {
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
            return target;
    }

    export function update_elements(ckt, elements, schema_editor) {
        for (const [ckt_name, elms] of Object.entries(ckt.elements)) {
            if (ckt_name[0] == ".") {
                continue;
            }
            let target = schema_file(ckt_name, schema_editor)
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
                return [update_elms, target];
            }
        }
        return ['', null];
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
    
    export function info_translated(info, proj) {
        if (info == null) return null;
        if (proj.ctl_type == "ngspctl") {
          //return .map(a => {
        return [info[0]].concat(info.slice(1).map((a) => translate(a)));
        } else {
          return info;
        }
    }

    function translate(a) {
        let m;
        if ((m = a.match(/(.+)#branch/))) {
          return `I(${m[1]})`;
        } else {
          return `V(${a})`;
        }
    }
</script>

<script lang="ts">
    import { get_control,  } from "./openCircuit.svelte";
    import { proj, ckt } from "./shared.svelte";
    import { tooltip, msg } from "./Utils/tooltip.svelte";
    //import { getJSONfromGrape } from "./plotResults.svelte";

  export async function goLTspice() {
        console.log('ckt=', $state.snapshot(ckt));
        console.log('proj.elements=', $state.snapshot(proj.elements));
        if (ckt == undefined || Object.keys(proj.elements).length == 0 || proj.ckt == '') {
            alert("Please read-in the circuit before simulation");
            return;
        }
        console.log(`openCircuit dir='${proj.dir}' file='${proj.file}'`);
        //dispatch("elm_update", { text: "Update elements" });
        //update_elements(port, proj.dir, ckt, proj.elements, probes, proj.schema_editor);
        
        console.log("variations", $state.snapshot(variations));
        let encoded_params = `dir=${encodeURIComponent(
            proj.dir,
        )}&file=${encodeURIComponent(
            proj.file,
        )}&probes=${encodeURIComponent(
                probes,
        )}&variations=${encodeURIComponent(JSON.stringify(variations))}`;
        //let elements_update = undefined;
        //let target = undefined;
        const [elements_update, target] = update_elements(ckt, proj.elements, proj.schema_editor);

        if (elements_update != '') {
            console.log('target=', target)
            console.log(
                "update elements=",
                $state.snapshot(proj.elements),
                ` here @ proj.dir= ${proj.dir} file=${target}`,
            );
            encoded_params =
                encoded_params +
                `&elements_update=${encodeURIComponent(`{${elements_update}}`)}`;
        }  
        const models_update = update_models(ckt, proj.models);
        if (models_update != {}) {
            encoded_params =
                encoded_params +
                `&models_update=${encodeURIComponent(JSON.stringify(models_update))}`;
        }
        // dispatch("sim_start", { text: "LTspice simulation started!" });
        on_sim_start("Simulation started!");
        const command = `http://localhost:${port}/api/${proj.ctl_type}/simulate?${encoded_params}`;
		console.log(command);
        let response = await fetch(command, {});
        let res2 = await response.json();
        if (res2.error) {
          alert(res2.error);
          return;
        }
        console.log(res2);
        if (res2.keys != '') {
            let performances = res2.keys;
        }
        if (elements_update != ''){
            let elements = res2.updates;
            for (const [ckt_name, elms] of Object.entries(ckt.elements)) {
                if (ckt_name[0] == ".") {
                    continue;
                }
                for (const [elm, props] of Object.entries(ckt.elements)) {
                    //if (elements[ckt_name][elm] != get_control(props)) {
                    if (elements[elm] != get_control(props)) {
                        console.log(
                            `Update error! ${elm}: ${get_control(props)}vs.${
                                //elements[ckt_name][elm]
                                elements[elm]
                            }`,
                        );
                    }
                }
            }
        }
        //res2 = await getJSONfromGrape(`http://localhost:${port}/api/${proj.ctl_type}/info?${encoded_params}`);
        ckt.info = info_translated(res2.info, proj);
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
