<script module>
  import { switch_wdir } from "./openCircuit.svelte";
  export async function edif2ltspice(port, dir, chosen){
    console.log(`convert_edif port=${port} dir='${dir}' chosen='${chosen}'`);
    let encoded_params = `dir=${encodeURIComponent(
        dir,
      )}&file=${encodeURIComponent(chosen)}`
    let response = await fetch(
      `http://localhost:${port}/api/ltspctl/convert_edif?${encoded_params}`,
      {},
    );
    let res2 = await response.json();
    console.log(res2);
    switch_wdir(dir, false);
  }
</script>
<script lang="ts">
    import { enhance, applyAction } from "$app/forms";
    import { goto } from "$app/navigation";
    import { proj } from "./shared.svelte";
    import { tooltip, msg } from "./Utils/tooltip.svelte";
    let { port, dir, editor = $bindable(), chosen } = $props();

    // function convertSchematic(selected) {
    //    alert("conversion to " + selected);
    // }
    let selected = $state();
    let to_program = $derived.by(() => {
        console.log`selected = ${selected}`;
                switch (selected) {
                    case "Xschem":
                        return `
                create_cdraw();
                dir = Dir.pwd;
                cdraw2target 'xschem', File.join(dir,'cdraw'), File.join(dir, '${selected}')
                `;
                        break;
                    case "LTspice":
                        return `
                dir = Dir.pwd;
                xschem2cdraw dir, File.join(dir, '${selected}')
                `;
                        break;
        }
    });
    function encoded_params(dir, program) {
        console.log(`dir=${encodeURIComponent(dir)}`);
        console.log(`program=${program}`);
        return `dir=${encodeURIComponent(dir)}&program=${program}`;
    }
    async function convert_edif(chosen) {
        if (chosen != undefined ) {
            edif2ltspice(port, dir, chosen); // I don't know where 'dir' comes from
            return;
        }
        const pickerOpts = {
            types: [
                { description: "EDIF(.edif/out)", accept: { "edif/*": [".edif", ".out"] } },
            ],
            multiple: false,
        };
        let fileHandle;
        [fileHandle] = await window.showOpenFilePicker(pickerOpts);
        const file = await fileHandle.getFile();
        let edifdata = await file.text();
        console.log('File name:', file.name, 'size=', edifdata.length);
        const props = {};
        props.wdir = dir;
        props.edifdata = edifdata;
        props.file_name = file.name;
        const response = await fetch("", {
            method: "POST",
            body: JSON.stringify(props),
            headers: {
            "Content-Type": "application/json",
            },
        });
        edif2ltspice(port, dir, file.name);
    }
</script>

<!-- form method="POST" on:submit={handleSubmit} class='button-2'></form -->
<form
    method="POST"
    use:enhance={({ formElement, formData, action, cancel }) => {
        return async ({ result }) => {
            proj.schema_editor = selected;
            console.log("result=", result);
            if (dir == undefined || dir == "") {
                alert("Conversion failed --- please read-in the circuit data");
            } else {
                alert(`${selected} folder created under ${dir}`);
            }
            window.location =
                "?wdir=" + dir.replace(/^"/, "").replace(/"$/, "") + selected;
            editor = selected;
        };
    }}
    class="button-2"
        action={`http://localhost:${port}/api/misc/convert_circuit_data?${encoded_params(
        dir,
        to_program,
    )}`}
>
    <button>Convert circuit data</button
    >
    to
    <!--input name={selected} / -->
    <input name="to_program" value={to_program} type="hidden" />
    <select bind:value={selected}>
        {#if editor != " Xschem"}<option value="Xschem">Xschem</option>{/if}
        {#if editor != " LTspice"}<option value="LTspice">LTspice</option>{/if}
        {#if editor != " EESchema"}<option value="EEschema">EEschema</option
            >{/if}
        {#if editor != " Qucs"}<option value="Qucs">Qucs</option>{/if}
        {#if editor != " Edif"}<option value="Edif">Edif</option>{/if}
    </select>
    Current:
    <select bind:value={proj.schema_editor}>
        <option value="Xschem">Xschem</option>
        <option value="LTspice">LTspice</option>
        <option value="EEschema">EEschema</option>
        <option value="Qucs">Qucs</option>
        <option value="Edif">Edif</option>
    </select>
</form>
{#if proj.schema_editor == 'LTspice'}
<button
    use:tooltip={() => msg("Convert from Edif file")}
    onclick={() => convert_edif(chosen)}
    class="button-2">Convert from Edif file</button
>
{/if}
<style>
</style>
