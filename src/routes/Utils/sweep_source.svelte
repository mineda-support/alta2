<script>
    import InputValue from "./input_value.svelte";
    export let src;
    export let par_name;
    export let src_values;
    export let src_plus;
    export let sweep_type='Linear';
    export let start_lin_val;
    export let stop_lin_val;
    export let lin_incr;
    export let src_value;
    export let start_dec_val;
    export let stop_dec_val;
    export let dec_points;
    export let start_oct_val;
    export let stop_oct_val;
    export let oct_points;
    export let elements;
    export let source_title;
    export let src_precision=3;

    function set_src_values() {
        console.log("sweep type:", sweep_type);
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
        }
        console.log(src_values);
    }
    function add_additional_source() {
        src_plus ||= [];
        if (src.match(/:M/)) {
            src_plus.push(src + ':' + par_name);
        } else if (src.match(/:X/)) {
            // just ignore
        } else {
            src_plus.push(src);
        }
        console.log("src_plus=", src_plus);
    }
    function clear_additional_source(){
        src_plus ||= [];
        src_plus.pop();
        console.log("src_plus=", src_plus);
    }
    let value_list=[];
</script>

<div>
    <label
        >{source_title}
        <select bind:value={src} style="border:darkgray solid 1px;">
            {#each Object.entries(elements) as [ckt_name, elms]}
                {#each Object.keys(elms) as elm}
                    <option value={[ckt_name, elm].join(":")}
                        >{[ckt_name, elm].join(":")}</option
                    >
                {/each}
            {/each}
        </select>
        {#if src != undefined && src.match(/:M/)}
            <select bind:value={par_name} style="border:darkgray solid 1px;">
                <option value="l">l</option>
                <option value="w">w</option>
            </select>
        {/if}
        <label>
            <button on:click={add_additional_source} class="button-1">
                add
            </button> {src_plus ? src_plus.join('&') : ''}
        </label>
        <label>
            <button on:click={clear_additional_source} class="button-1">
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
                <InputValue lab="Start" bind:val={start_lin_val} />
                <InputValue lab="Stop" bind:val={stop_lin_val} />
                <InputValue lab="Increment" bind:val={lin_incr} />
            {/if}
            {#if sweep_type == "Decade"}
                <InputValue lab="# of points /dec." bind:val={dec_points} />
                <InputValue lab="Start" bind:val={start_dec_val} />
                <InputValue lab="Stop" bind:val={stop_dec_val} />
            {/if}
            {#if sweep_type == "Octave"}
                <InputValue lab="# of points /oct." bind:val={oct_points} />
                <InputValue lab="Start" bind:val={start_oct_val} />
                <InputValue lab="Stop" bind:val={stop_oct_val} />
            {/if}
            {#if sweep_type == "List"}
                <label
                    >List
                    <input
                        bind:value={value_list}
                        style="border:darkgray solid 1px;"
                    /></label
                >
            {/if}
            <button on:click={set_src_values} class="button-1"
                >Set source values</button
            >
            <label>precision:
        <input value={src_precision} />
            </label>
        </div>

        {src} =&gt;{src_values} 
    </label>
</div>

<style>
</style>
