<script lang="ts">
    import { enhance, applyAction } from "$app/forms";
    import { goto } from "$app/navigation";
    import { proj } from "./shared.svelte";
    import { tooltip, msg } from "./Utils/tooltip.svelte";
    let { port, dir, editor = $bindable() } = $props();

    // function convertSchematic(selected) {
    //    alert("conversion to " + selected);
    // }
    let selected = $state();
    let to_program = $derived.by(() => {
        console.log`selected = ${selected}`;
                switch (selected) {
                    case "Xschem":
                        return `
                create_cdraw()
                dir = Dir.pwd
                cdraw2target 'xschem', File.join(dir,'cdraw'), File.join(dir, '${selected}')
                `;
                        break;
                    case "LTspice":
                        return `
                dir = Dir.pwd
                xschem2cdraw dir, File.join(dir, '${selected}')
                `;
                        break;
        }
    });
    let from_program = $derived.by(() => {
        console.log`selected = ${selected}`;
                switch (selected) {
                    case "Edif":
                        return `
                create_cdraw()
                dir = Dir.pwd
                cdraw2target 'xschem', File.join(dir,'cdraw'), File.join(dir, '${selected}')
                `;
                        break;
                    case "LTspice":
                        return `
                dir = Dir.pwd
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
    async function convert_edif() {
        const pickerOpts = {
            types: [
                { description: "EDIF(.edif)", accept: { "edif/*": [".edif"] } },
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
    action={`http://localhost:${port}/api/ltspctl/convert_to_${selected}?${encoded_params(
        dir,
        to_program,
    )}`}
>
    <button>Convert schematic</button
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
    onclick={() => convert_edif()}
    class="button-2">Convert from Edif file</button
>
{/if}
<style>
</style>
