<script lang="ts">
   import { enhance, applyAction } from "$app/forms";
   import { goto } from "$app/navigation";
   let { dir, port } = $props();

    // function convertSchematic(selected) {
    //    alert("conversion to " + selected);
    // }
    let selected = $state();
    let program = $derived(
   `
   create_cdraw()
   dir = Dir.pwd
   cdraw2target 'xschem', File.join(dir,'cdraw'), File.join(dir, '${selected}')
   `);

    function encoded_params(dir, program) {
        console.log(`dir=${encodeURIComponent(dir)}`);
        return `dir=${encodeURIComponent(dir)}&program=${program}`;
    }
 </script>

<!-- form method="POST" on:submit={handleSubmit} class='button-2'></form -->
<form
    method="POST"
    use:enhance={({ formElement, formData, action, cancel }) => {
        return async ({ result }) => {
            console.log('result=', result);
            // `result` is an `ActionResult` object --- this is not true 
            /* if (result.type === "redirect") {
                //goto(result.location);
                window.location = result.location;
            } else {
                await applyAction(result);
            } */
            if (dir == undefined || dir == '') {
                alert('Conversion failed --- please read-in the circuit data');
            } else {
                alert(`Xschem folder created under ${dir}`);
            }
            window.location = "?wdir=" + dir.replace(/^"/, "").replace(/"$/, "")+selected;
        };
    }}
    class="button-2"
    action={`http://localhost:${port}/api/ltspctl/convert_from_LTspice?${encoded_params(
        dir, program
    )}`}
>
    <button>Convert schematic</button> to
    <!--input name={selected} / -->
    <input name="program" value={program} type="hidden" />
    <select bind:value={selected}>
        <option value="Xschem">Xschem</option>
        <option value="EEschema">EEschema</option>
        <option value="Qucs">Qucs</option>
        <option value="Edif">Edif</option>
    </select>
</form>
<style>
</style>
