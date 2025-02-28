<script lang="ts">
    import InputValue from "./input_value.svelte";
    import { tooltip, msg } from "./tooltip.svelte";
    let {
        source_title,
        src = $bindable(),
        src_precision = $bindable(), // (3)
        par_name = $bindable(),
        src_values = $bindable(),
        src_plus = $bindable(),
        sweep_type = $bindable(), //'Linear'),
        start_lin_val = $bindable(),
        stop_lin_val = $bindable(),
        lin_incr = $bindable(),
        start_dec_val = $bindable(),
        stop_dec_val = $bindable(),
        dec_points = $bindable(),
        start_oct_val = $bindable(),
        stop_oct_val = $bindable(),
        oct_points = $bindable(),
        elements,
    } = $props();

    function set_src_values() {
        console.log("sweep type:", sweep_type);
        console.log("src_precision=", src_precision)
        src_values = [];
        switch (sweep_type) {
            case "Linear":
                console.log("start:", start_lin_val);
                console.log("stop:", stop_lin_val);
                console.log("increment:", lin_incr);
                for (
                    let val = Number(start_lin_val);
                    val <= Number(stop_lin_val);
                    val = val + Number(lin_incr)
                ) {
                    src_values.push(val.toPrecision(src_precision));
                }
                break;
            case "Decade":
                console.log("Decade");
                let log10start = Math.log10(Number(start_dec_val));
                console.log("start=", log10start);
                let log10stop = Math.log10(Number(stop_dec_val));
                console.log("stop=", log10stop);
                let incr = 1.0 / Number(dec_points);
                console.log("incr=", incr);
                for (let i = log10start; i <= log10stop; i = i + incr) {
                    console.log(i);
                    src_values.push(Math.pow(10, i));
                }
                break;
            case "List":
                src_values = value_list.split(",").map((a) => a.trim());
                break;
        }
        console.log($state.snapshot(src_values));
    }
    function add_additional_source() {
        src_plus ||= [];
        if (src.match(/:M/)) {
            src_plus.push(src + ":" + par_name);
        } else if (src.match(/:X/)) {
            // just ignore
        } else {
            src_plus.push(src);
        }
        console.log("src_plus=", $state.snapshot(src_plus));
    }
    function clear_additional_source() {
        src_plus ||= [];
        src_plus.pop();
        console.log("src_plus=", $state.snapshot(src_plus));
    }
    let value_list = $state([]);
</script>

<div>
    <label
        >{source_title}
        <select bind:value={src} style="border:darkgray solid 1px;">
            {#if elements != undefined}
                {#each Object.entries(elements) as [ckt_name, elms]}
                    {#each Object.keys(elms) as elm}
                        <option value={[ckt_name, elm].join(":")}
                            >{[ckt_name, elm].join(":")}</option
                        >
                    {/each}
                {/each}
            {/if}
        </select>
        {#if src != undefined && src.match(/:M/)}
            <select bind:value={par_name} style="border:darkgray solid 1px;">
                <option value="l">l</option>
                <option value="w">w</option>
            </select>
        {/if}
        <label>
            <button
                use:tooltip={() => msg("add a source parameter to sweep")}
                onclick={add_additional_source}
                class="button-1"
            >
                add
            </button>
            {src_plus ? src_plus.join("&") : ""}
        </label>
        <label>
            <button
                use:tooltip={() => msg("clear a last added source parameter")}
                onclick={clear_additional_source}
                class="button-1"
            >
                clear
            </button>
        </label>
        <div>
            <select bind:value={sweep_type} style="border:darkgray solid 1px;">
                <option value="Linear">Linear</option>
                <option value="Octave">Octave</option>
                <option value="Decade">Decade</option>
                <option value="List">List</option>
            </select>
            {#if sweep_type == "Linear"}
                <!-- label>Start
			<input
				bind:value={settings.start_value1}
				style="border:darkgray solid 1px;"
			/></label -->
                <InputValue
                    tooltip_msg="set start for a source parameter"
                    lab="Start"
                    bind:val={start_lin_val}
                />
                <InputValue
                    tooltip_msg="set stop for a source parameter"
                    lab="Stop"
                    bind:val={stop_lin_val}
                />
                <InputValue
                    tooltip_msg="set increment for a source parameter"
                    lab="Increment"
                    bind:val={lin_incr}
                />
            {/if}
            {#if sweep_type == "Decade"}
                <InputValue
                    tooltip_msg="set number of points per decade for a source parameter"
                    lab="# of points /dec."
                    bind:val={dec_points}
                />
                <InputValue
                    tooltip_msg="set start for a decade sweep source parameter"
                    lab="Start"
                    bind:val={start_dec_val}
                />
                <InputValue
                    tooltip_msg="set stop for a decade sweep source parameter"
                    lab="Stop"
                    bind:val={stop_dec_val}
                />
            {/if}
            {#if sweep_type == "Octave"}
                <InputValue
                    tooltip_msg="set number of points per octave for a source parameter"
                    lab="# of points /oct."
                    bind:val={oct_points}
                />
                <InputValue
                    tooltip_msg="set stop for an octave sweep source parameter"
                    lab="Start"
                    bind:val={start_oct_val}
                />
                <InputValue
                    tooltip_msg="set stop for an octave sweep source parameter"
                    lab="Stop"
                    bind:val={stop_oct_val}
                />
            {/if}
            {#if sweep_type == "List"}
                <label
                    use:tooltip={() =>
                        msg(
                            "set a list of points separated by comma for sweep source parameter",
                        )}
                    >List
                    <input
                        bind:value={value_list}
                        style="border:darkgray solid 1px;"
                    /></label
                >
            {/if}
            <div>
                <button
                    use:tooltip={() => msg("generate source parameter values")}
                    onclick={set_src_values}
                    class="button-1">Set source values</button
                >
                <label
                    use:tooltip={() =>
                        msg("set precision for source parameter numbers")}
                    >precision:
                    <input bind:value={src_precision} style="width:5%"/>
                </label>
            </div>
        </div>
        Sweep '{src}' =&gt;{src_values}
    </label>
</div>

<style>
</style>
