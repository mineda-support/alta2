<script module>
    function get_sweep_values(plotdata) {
        let values = [];
        let sweep, value;
        console.log("plotdata in get_sweep_values=", $state.snapshot(plotdata));
        plotdata.forEach((trace) => {
            [sweep, value] = trace.name.split("=");
            values.push(Number(value));
        });
        return values;
    }

    function get_performance(rows, index) {
        let values = [];
        rows.forEach((row) => {
            values.push(row[index]);
        });
        return values;
    }

    export async function measurement_results(
        port,
        dir,
        measfile,
        selection,
        reverse,
        invert_x,
        invert_y,
        tracemode,
    ) {
        console.log(measfile);
        console.log(
            `reverse=${reverse}, invert_x=${invert_x}, invert_y=${invert_y}, tracemode: ${tracemode}`,
        );
        //console.log(handle.name);
        //const file = await handle.getFile();
        //console.log(file);
        console.log("dir=", dir);
        let encoded_params = `dir=${encodeURIComponent(dir)}&file=${encodeURIComponent(measfile)}&selection=${selection}`;
        if (invert_x != undefined) {
            encoded_params = encoded_params + `&invert_x=${invert_x}`;
        }
        if (invert_y != undefined) {
            encoded_params = encoded_params + `&invert_y=${invert_y}`;
        }
        let response = await fetch(
            `http://localhost:${port}/api/misc/measured_data?${encoded_params}`,
            {},
        );
        let res2 = await response.json();
        console.log("res2=", res2);
        let measdata = reverse ? res2.traces.reverse() : res2.traces;
        console.log("measdata=", measdata);
        for (const trace of measdata) {
            trace.checked = true;
            trace.mode = tracemode;
        }
        console.log("measdata:", measdata);
        return measdata;
    }

    export async function plot_result(
        port,
        dir,
        file,
        probes,
        equation,
        plotdata,
        db_data,
        ph_data,
        elements,
        step_precision,
        sweep_name,
    ) {
        // cookies.et('probes', probes, { path: '/conditions'});
        console.log(
            `Plot results@dir='${dir}' file='${file}' probes=${probes}`,
        );
        if (probes == undefined) {
            alert("Simulation completed but probes for plot are not defined");
            return;
        }
        if (probes != probes.trim()) {
            alert("probes have unwanted leading space(s)");
            return;
        }
        const encoded_params = `dir=${encodeURIComponent(
            dir,
        )}&file=${encodeURIComponent(file)}&probes=${encodeURIComponent(
            probes,
        )}&equation=${encodeURIComponent(equation)}`;
        let response = await fetch(
            `http://localhost:${port}/api/ltspctl/results?${encoded_params}`,
            {},
        );
        let res2 = await response.json();
        console.log(res2);
        console.log("probes=", probes);
        if (probes != undefined && probes.trim().length > 0) {
            [plotdata, db_data, ph_data, sweep_name] = set_trace_names(
                res2,
                probes,
                proj.elements,
                step_precision,
            );
        }
        return [plotdata, db_data, ph_data, sweep_name];
    }
</script>

<script lang="ts">
    import BodePlot from "./utils/bode_plot.svelte";
    import SinglePlot from "./utils/single_plot.svelte";
    import { set_trace_names } from "./experiment.svelte";
    import { proj, ckt, settings } from "./shared.svelte.js";
    import { tooltip, msg } from "./Utils/tooltip.svelte";
    let {
        port,
        plot_number = $bindable(),
        current_plot = $bindable(),
        plot_showhide = $bindable(),
        results_data = $bindable(),
        measfile = $bindable(),
        step_precision = $bindable(),
        title = $bindable(),
        title_x = $bindable(),
        title_y = $bindable(),
        title_y1 = $bindable(),
        title_y2 = $bindable(),
        xaxis_is_log = $bindable(),
        yaxis_is_log = $bindable(),
        equation = $bindable(),
        performance_names = $bindable(),
        probes = $bindable(),
        plotdata = $bindable(),
        db_data = $bindable(),
        ph_data = $bindable(),
        measdata = $bindable(),
        calculated_value = $bindable(),
        selection = $bindable(),
        reverse = $bindable(),
        invert_x = $bindable(),
        invert_y = $bindable(),
        tracemode = $bindable(),
    } = $props();

    let sweep_name;
    let performances = $derived(
        settings.performance_names[settings.plot_number]
            .split(",")
            .map((a) => a.trim()),
    );

    const options = {
        types: [
            {
                description: "CSV Files",
                accept: {
                    "text/plain": [".csv", ".txt", ".text"],
                },
            },
        ],
    };

    async function get_measurement_results(
        port,
        dir,
        measfile,
        selection,
        reverse,
        invert_x,
        invert_y,
        tracemode,
    ) {
        if (measfile == undefined || measfile == "") {
            const [handle] = await window.showOpenFilePicker(options);
        }
        measdata = await measurement_results(
            port,
            dir,
            measfile,
            selection,
            reverse,
            invert_x,
            invert_y,
            tracemode,
        );
        measdata = measdata;
        console.log("measdata =", measdata);
    }
    function check_probes_valid() {
        console.log('probes=', probes);
        let count = 0;
        for(let c of probes){
            if (c == '(') { count++
            } else if (c == ')') {count-- }
        }
        if (count != 0) {
            alert(`parentheses do not match in '${probes}'`);
            return false;
        }
        const sweep_var = probes.match(/\w+,/)[0].replace(",", "");
        if (probes.includes(sweep_var)) {
            // like 'frequency'
            for (let match_string of probes.matchAll(/\w*\(\w+\)|\w+,|\w+$/g)) {
                let node = match_string[0].replace(",", "").trim();
                console.log("node=", node);
                if (!ckt.info.includes(node)) {
                    alert(`${node} is not a valid probe name`);
                    return false;
                }
            }
            return true;
        }
        return false;
    }
    async function plot_result_clicked() {
        if (!check_probes_valid()) return;
        let result = await plot_result(
            port,
            proj.dir,
            proj.file,
            probes,
            equation,
            plotdata,
            db_data,
            ph_data,
            proj.elements,
            step_precision,
            sweep_name,
        );
        [plotdata, db_data, ph_data, sweep_name] = result;
    }

    step_precision = 3;
    yaxis_is_log = false;
    xaxis_is_log = false;
    function clear_plot() {
        plotdata = db_data = ph_data = undefined;
    }
    function clear_measdata() {
        measdata = [];
    }
    function checkall_measdata() {
        console.log(measdata);
        for (const trace of measdata) {
            trace.checked = true;
        }
    }
    /* function redraw() {
        plotdata = plotdata;
        db_data = db_data;
        ph_data = ph_data;
        console.log('plotdata', plotdata);
    } */
    function calculate_equation() {
        submit_equation(
            port,
            equation,
            proj.dir,
            proj.file,
            plotdata,
            db_data,
            ph_data,
            measdata == undefined
                ? []
                : measdata.filter((trace) => trace.checked),
        );
        console.log(
            "values in calculate_equation:",
            $state.snapshot(calculated_value),
        );
        const equation_array = equation.split(",");
        if (performances == undefined) {
            alert("Performance name(s) for equation(s) not defined");
            return;
        }
        console.log("performances =", $state.snapshot(performances));
        performances.forEach(function (perf, index) {
            //console.log("perf, index=", [perf, index]);
            //console.log('results_data:', results_data);
            //if (calculated_value != undefined) {
            if (results_data[0][perf] == undefined) {
                results_data[0][perf] = [];
            }
            if (calculated_value != undefined) {
                results_data[0][perf].push({
                    x: get_sweep_values(
                        plotdata != undefined ? plotdata : db_data,
                    ),
                    y: get_performance(calculated_value, index),
                    name: equation_array[index],
                });
            }
            //} else {
            //	console.log('Error: calculate value is not available yet');
            //}
            //console.log(`results_data[0][${perf}]=`, results_data[0][perf]);
        });
        // results_data[0] = results_data[0];
        console.log("results_data=", $state.snapshot(results_data));
    }
    /*
    function select(measdata, selection) {
        const sel_list = selection.split(',');
        let selected_data = [];
        // performances = performance_names.split(",").map((a) => a.trim());
        measdata.forEach((row => {
            let new_row = sel_list.map((a) => row[a]);
            selected_data.push(new_row);
        }));
    }
*/
    async function submit_equation(
        port,
        equation,
        dir,
        file,
        plotdata,
        db_data,
        ph_data,
        measdata,
    ) {
        const encoded_params = `dir=${encodeURIComponent(
            dir,
        )}&file=${encodeURIComponent(file)}`;
        console.log(`equation to send: ${equation}`);
        console.log(
            "plotdata:",
            $state.snapshot(plotdata),
            "db_data:",
            $state.snapshot(db_data),
            "ph_data:",
            $state.snapshot(ph_data),
        );
        const res = await fetch(
            `http://localhost:${port}/api/ltspctl/measure?${encoded_params}`,
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    equation: equation,
                    plotdata: plotdata ? plotdata.concat(measdata) : [],
                    db_data: db_data ? db_data : [],
                    ph_data: ph_data ? ph_data : [],
                }),
            },
        );
        let result = await res.json();
        //console.log('result in submit_equation:', result);
        if (plotdata != undefined) {
            calculated_value = result.calculated_value.slice(
                0,
                plotdb_datadata.length,
            );
            if (measdata.length > 0) {
                alert(
                    result.calculated_value.slice(plotdata.length).join("\n"),
                );
            }
        } else {
            calculated_value = result.calculated_value.slice(0);
        }
        console.log("calculated_value=", $state.snapshot(calculated_value));
        // return calculated_value; // maybe useless
    }
    equation = "x.where(y, 2.5){|x, y| x > 1e-6}";
</script>

<button
    use:tooltip={() => msg("show or hide plot settings")}
    onclick={() => (plot_showhide = !plot_showhide)}
    class="button-2">Show/hide</button
>plot#{plot_number}
{#if plot_showhide}
    <button
        use:tooltip={() => msg("make this plot current to push probes")}
        onclick={() => (current_plot = plot_number)}
        class="button-2">Make current</button
    >
    <div>
        <button
            use:tooltip={() => msg("get a measurement data file")}
            onclick={() =>
                get_measurement_results(
                    port,
                    proj.dir,
                    measfile.trim().replace(/^"/, "").replace(/"$/, ""),
                    selection,
                    reverse,
                    invert_x,
                    invert_y,
                    tracemode,
                )}
            class="button-1">Get measured data:</button
        >
        <input
            bind:value={measfile}
            style="border:darkgray solid 1px; width:40%;"
        />
        <label
            use:tooltip={() =>
                msg("select two data columns to display in a graph")}
            >Selection:<input
                bind:value={selection}
                style="border:darkgray solid 1px; width:5%"
            /></label
        >
        <br />
        <label use:tooltip={() => msg("reverse traces in a graph")}
            >Selection:<input />Reverse<input
                type="checkbox"
                bind:checked={reverse}
            /></label
        >
        <label use:tooltip={() => msg("invert X data")}
            >InvertX<input type="checkbox" bind:checked={invert_x} /></label
        >
        <label use:tooltip={() => msg("invert Y data")}
            >InvertY<input type="checkbox" bind:checked={invert_y} /></label
        >
        <button
            use:tooltip={() =>
                msg("select trace mode from, markers, lines, markers+lines")}
            >Trace mode</button
        >
        <input name="tracemodes" value={tracemode} type="hidden" />
        <select bind:value={tracemode} style="border:darkgray solid 1px;">
            <option value="markers">markers</option>
            <option value="lines">lines</option>
            <option value="lines+markers">lines+markers</option>
        </select>
    </div>
    {#if measdata != undefined && measdata != "" && measdata != []}
        <div style="border:green solid 2px;">
            {#each measdata as trace}
                <label
                    >{trace.name}
                    <input
                        style="border:darkgray solid 1px;"
                        type="checkbox"
                        bind:checked={trace.checked}
                    />
                </label>
            {/each}
            <button onclick={checkall_measdata} class="button-1"
                >check all</button
            >
            <button onclick={clear_measdata} class="button-1">clear all</button>
        </div>
    {/if}
    <button
        use:tooltip={() =>
            msg("set probes list (separated by comma) for a current plot")}
        onclick={plot_result_clicked}
        class="button-1">Plot with probes:</button
    >
    <input bind:value={probes} style="border:darkgray solid 1px;" />
    <label
        use:tooltip={() =>
            msg("set probes list (separated by comma) for a current plot")}
        >step precision:
        <input bind:value={step_precision} />
    </label>

    {#if probes == undefined || !probes.startsWith("frequency")}
        <label use:tooltip={() => msg("X axis is log scale if checked")}>
            <input type="checkbox" bind:checked={xaxis_is_log} />
            xaxis is log
        </label>
        <label use:tooltip={() => msg("Y axis is log scale if checked")}>
            <input type="checkbox" bind:checked={yaxis_is_log} />
            yaxis is log
        </label>
    {/if}
    <label>
        <button
            use:tooltip={() => msg("clear plot")}
            onclick={clear_plot}
            class="button-1">clear</button
        >
    </label>
    <!-- label>
        <button on:click={redraw} class="button-1">redraw</button>
    </label -->
    <div>
        <label use:tooltip={() => msg("title for a graph")}
            >Title
            <input bind:value={title} style="border:darkgray solid 1px;" />
        </label>
        <label use:tooltip={() => msg("X axis title")}
            >X title
            <input bind:value={title_x} style="border:darkgray solid 1px;" />
        </label>
        {#if probes == undefined || !probes.startsWith("frequency")}
            <label use:tooltip={() => msg("Y axis title")}
                >Y title
                <input
                    bind:value={title_y}
                    style="border:darkgray solid 1px;"
                />
            </label>
        {:else}
            <label
                >Y1 title
                <input
                    bind:value={title_y1}
                    style="border:darkgray solid 1px;"
                />
            </label>
            <label
                >Y2 title
                <input
                    bind:value={title_y2}
                    style="border:darkgray solid 1px;"
                />
            </label>
        {/if}
    </div>
{/if}
{#if plotdata !== undefined}
    <SinglePlot
        {plotdata}
        {measdata}
        {title}
        {title_x}
        {title_y}
        {xaxis_is_log}
        {yaxis_is_log}
    />
{/if}
{#if probes != undefined && probes.startsWith("frequency") && db_data !== undefined && ph_data !== undefined}
    <BodePlot {db_data} {ph_data} {title} {title_x} {title_y1} {title_y2} />
{/if}

{#if plot_showhide}
    <div>
        <label use:tooltip={() => msg("performance names separated by commaa")}>
            Performance name(s)
            <input
                bind:value={performance_names}
                style="border:darkgray solid 1px;"
            />
        </label>
    </div>
    <div>
        <label
            use:tooltip={() => msg("performance equations in an array format")}
            >Equation(s)
            <input
                bind:value={equation}
                style="border:darkgray solid 1px; width: 50%"
            />
            <button
                use:tooltip={() =>
                    msg("calculate equations for a current plot")}
                onclick={() => calculate_equation(results_data[0])}
                class="button-1"
            >
                Calculate</button
            >
            {#if Array.isArray(calculated_value)}
                <table>
                    <thead>
                        <tr>
                            {#each performances as perf}
                                <th>{perf}</th>
                            {/each}
                            <th>Sweep parameter</th>
                        </tr>
                    </thead>
                    <tbody>
                        {#each calculated_value as vals, i}
                            <tr>
                                {#each vals as val}
                                    <td>{val}</td>
                                {/each}
                                <td>{plotdata == undefined ? db_data[i].name : plotdata[i].name}</td>
                            </tr>
                        {/each}
                    </tbody>
                </table>
            {/if}
        </label>
    </div>
    <hr />
{/if}

<style>
    label {
        font-family: Arial, "Helvetica Neue", "BIZ UDPGothic", Meiryo,
            "Hiragino Kaku Gothic Pro", sans-serif;
        font-size: 10pt;
    }
</style>
