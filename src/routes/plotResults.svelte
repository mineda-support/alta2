<script module>
    export function get_sweep_values(plotdata, nv=1) {
        let values = [];
        let sweep, value;
        console.log("plotdata in get_sweep_values=", $state.snapshot(plotdata));
        plotdata.forEach(function(trace, index){
            if(index % nv == 0) {
              [sweep, value] = trace.name.split("=");
              values.push(Number(value));
            }
        });
        return values;
    }

    export function get_performance(rows, index) {
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
        calculated_value,
        plotdata,
        db_data,
        ph_data,
        elements,
        step_precision,
        sweep_name,
        performance_names,
    ) {
        // cookies.et('probes', probes, { path: '/conditions'});
        console.log(
            `Plot results@dir='${dir}' file='${file}' probes='${probes}'`,
        );
        if (probes == undefined || probes.trim() == '') {
            //if (ckt.info != undefined && ckt.info != []) {
            //    alert("Simulation completed but probes for plot are not defined");
            //} else {
                alert("Please set probes");
            //}    
            return;
        } else if (probes != probes.trim()) {
            alert("probes have unwanted leading space(s)");
            return;
        }
        const encoded_params = `dir=${encodeURIComponent(
            dir,
        )}&file=${encodeURIComponent(file)}&probes=${encodeURIComponent(
            probes,
        )}&equation=${encodeURIComponent(equation)}`;
        let response = await fetch(
            `http://localhost:${port}/api/${proj.ctl_type}/results?${encoded_params}`,
            {},
        );
        let res2 = await response.json();
        console.log(res2);
		if (res2.error) {
          alert(res2.error);
        }
        console.log("probes=", probes);
        if (probes != undefined && probes.trim().length > 0) {
            step_precision = 3; // step_precision = '' is weird!
            [plotdata, db_data, ph_data, sweep_name] = set_trace_names(
                // ignore weird probes change
                res2,
                probes,
                proj.elements,
                step_precision,
            );
        }
        if (res2.keys != undefined && res2.keys != '') {
          let performances = res2.keys;
          performance_names = performances.join(',');
          calculated_value = res2.calculated_value;

          performances.forEach(function (perf, index) {
            proj.results_data[0][perf] = [];
            proj.results_data[0][perf].push({
                x: get_sweep_values(
                        plotdata != undefined ? plotdata : db_data, probes.split(',').length - 1
                    ),
                y: get_performance(calculated_value, index),
                });
            });
        }
        return [plotdata, db_data, ph_data, sweep_name, probes, performance_names, calculated_value];
    }

	export async function getJSONfromGrape(url) {
        const controller = new AbortController()
        //const result = document.getElementById('result')
        //result.textContent = 'loading...'
        await setTimeout(() => controller.abort(), 3000)
        try {
          const res = await fetch(url, {
            signal: controller.signal
          })
          const json = await res.json()
          //await new Promise(p => setTimeout(p, 3000))
          /*
          if (res.ok) {
            result.innerHTML = JSON.stringify(json, null, '  ')
          } else {
            result.textContent = json
          } */
          return json;
        } catch(e) {
          if (e.name === 'AbortError') {
            //result.textContent = 'Timeout error'
            console.log('Timeout error');
          } else {
            //result.textContent = 'Network error'
            console.log('Network error');
          }
        }
    }	    
</script>

<script lang="ts">
    import BodePlot from "./Utils/bode_plot.svelte";
    import SinglePlot from "./Utils/single_plot.svelte";
    import { set_trace_names } from "./experiment.svelte";
    import { proj, ckt, settings } from "./shared.svelte.js";
    import { tooltip, msg } from "./Utils/tooltip.svelte";
    let {
        wdir,
        port,
        plot_number = $bindable(),
        current_plot = $bindable(),
        plot_showhide = $bindable(),
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
        chosen = $bindable(),
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
        console.log("measdata =", $state.snapshot(measdata));
    }
    function check_probes_valid() {
        console.log("probes=", probes);
        let count = 0;
        for (let c of probes) {
            if (c == "(") {
                count++;
            } else if (c == ")") {
                count--;
            }
        }
        if (count != 0) {
            alert(`parentheses do not match in '${probes}'`);
            return false;
        }
        const sweep_var = probes.match(/\w+,/)[0].replace(",", "");
        if (probes.includes(sweep_var)) {
            // like 'frequency'
            let probes_test = probes // JSON.parse(JSON.stringify(probes)); note: [...probes] is for array
            for (let node of ckt.info) {
                probes_test = probes_test.replace(node, '');
            }
            let nodes = probes_test.split(/[ ,\*\+-\/\(\)]/)
            for (let node of nodes) {
                if (!node.match(/[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?/) && node.trim.length != 0) {
                    alert(`${node} is not a valid probe name`);
                    return false;
                }
            }
            return true;
        }
        return false;
    }
    function plot_measured_data_only() {
        plotdata = [];
    }
    async function plot_result_clicked(step_precision) {
        /* if (ckt.info == undefined) {
            alert('Simulation results are not available');
            return;
        } */
        if (proj.simulator == "LTspice" && !check_probes_valid()) return;
        let result = await plot_result(
            port,
            proj.dir,
            proj.file,
            probes,
            equation,
            calculated_value,
            plotdata,
            db_data,
            ph_data,
            proj.elements,
            step_precision,
            sweep_name,
            performance_names,
        );
        if (result != undefined) {
            [plotdata, db_data, ph_data, sweep_name, probes, performance_names, calculated_value] = result;
            plot_showhide = false;
        }
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

    proj.results_data[0] = {};

    async function calculate_equation(probes) {
        proj.results_data = [];
        proj.results_data[0] = {};
        calculated_value = await submit_equation(
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
            probes
        );
        console.log(
            "calculated_value in calculate_equation:",
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
            //console.log('proj.results_data:', $state.snapshot(proj.results_data));
            //if (calculated_value != undefined) {
            if (proj.results_data[0][perf] == undefined) {
                proj.results_data[0][perf] = [];
            }
            if (calculated_value != undefined) {
                proj.results_data[0][perf].push({
                    x: get_sweep_values(
                        plotdata != undefined ? plotdata : db_data, probes.split(',').length - 1
                    ),
                    y: get_performance(calculated_value, index),
                    // name: equation_array[index],
                });
            }
        });
        console.log("proj.results_data=", $state.snapshot(proj.results_data));
    }
    async function submit_equation(
        port,
        equation,
        dir,
        file,
        plotdata,
        db_data,
        ph_data,
        measdata,
        probes
    ) {
        const encoded_params = `dir=${encodeURIComponent(
            dir,
        )}&file=${encodeURIComponent(file)}&probes=${encodeURIComponent(
            probes)}`;
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
            `http://localhost:${port}/api/${proj.ctl_type}/measure?${encoded_params}`,
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
		if (res.error) {
          alert(res.error);
          return;
        }
        let result = await res.json();
        //console.log('result in submit_equation:', result);
        if (plotdata != undefined) {
            calculated_value = await result.calculated_value.slice(
                0,
                plotdata.length,
            );
            if (measdata.length > 0) {
                alert(
                    result.calculated_value.slice(plotdata.length).join("\n"),
                );
            }
        } else {
            calculated_value = await result.calculated_value.slice(0);
        }
        console.log("calculated_value=", $state.snapshot(calculated_value));
        return calculated_value;
    }
    equation = '' /* "x.where(y, 2.5){|x, y| x > 1e-6}"; */

    function data2csv(csv_text, csv_data) {
        for (let j = 0; j < csv_data[0].length; j++) {
            for (let i = 0; i < csv_data.length; i++) {
                csv_text = csv_text + csv_data[i][j] + ", ";
            }
            csv_text = csv_text + "\n";
        }
        return csv_text;
    }
    async function save_csv() {
        let saveFileOptions = {
            suggestedName: "xxxxxx.csv",
            types: [
                {
                    description: "CSV Files",
                    accept: {
                        "application/csv": [".csv"],
                    },
                },
            ],
        };
        let csv_data;
        let x_data = undefined;
        let csv_text = "";
        if (plotdata == undefined) {
            alert(
                "Plotdata is not available until 'Plot with probes' performed",
            );
        }
        plotdata.forEach((trace) => {
            if (JSON.stringify(trace.x) === x_data) {
                console.log("x_data is same");
            } else {
                if (csv_data != undefined) {
                    csv_text = data2csv(csv_text, csv_data);
                }
                csv_data = [trace.x];
                csv_text = csv_text + probes.split(/, */)[0];
                x_data = JSON.stringify(trace.x);
            }
            csv_data.push(trace.y);
            csv_text = csv_text + ", " + trace.name;
        });
        csv_text = csv_text + "\n";
        csv_text = data2csv(csv_text, csv_data);
        const handle = await window.showSaveFilePicker(saveFileOptions);
        const ws = await handle.createWritable();
        await ws.write(csv_text);
        await ws.close();
    }
    async function save_json() {
        console.log("plotdata =", $state.snapshot(plotdata));
        if (plotdata == undefined && measdata.length == 0) {
            alert(
                "Plotdata is not available until 'Plot with probes' performed",
            );
        }
        let saveFileOptions = {
            suggestedName: "xxxxxx.json",
            types: [
                {
                    description: "JSON Files",
                    accept: {
                        "application/json": [".json"],
                    },
                },
            ],
        };
        const blob = JSON.stringify([
            settings,
            {
                plotdata: plotdata,
                measdata: measdata,
                db_data: db_data,
                ph_data: ph_data,
            },
        ]);
        const handle = await window.showSaveFilePicker(saveFileOptions);
        const ws = await handle.createWritable();
        await ws.write(blob);
        await ws.close();
    }

    function modify_data(plotdata) {
        console.log(
            `reverse=${reverse}, invert_x=${invert_x}, invert_y=${invert_y}, tracemode: ${tracemode}`,
        );
        let new_data = reverse ? plotdata.reverse() : plotdata;
        new_data.forEach((trace) => {
            if (invert_x) {
                trace.x = trace.x.map(a => -a)
            }
            if (invert_y) {
                trace.y = trace.y.map(a => -a)
            }
        });
        return new_data;
    }

    export async function read_json(port, dir, file) {
        if (file == undefined) {
            load_json();
            return;
        }
        let encoded_params = `dir=${encodeURIComponent(
            dir,
        )}&file=${encodeURIComponent(file)}`;
        let response = await fetch(
            `http://localhost:${port}/api/misc/read_json?${encoded_params}`,
            {},
        );
        let res = await response.json();
        let tmpsettings;
        let table;
        [tmpsettings, table] = res.json;
        plotdata = modify_data(table.plotdata);
        measdata = modify_data(table.measdata);
        // ckt_data.plotdata[current_plot] = plotdata;
    }

    async function load_json() {
        const pickerOpts = {
            types: [
                { description: "JSON(.json)", accept: { "json/*": [".json"] } },
            ],
            multiple: false,
        };
        let fileHandle;
        [fileHandle] = await window.showOpenFilePicker(pickerOpts);
        const file = await fileHandle.getFile();
        filename = file.name;
        let filedata = await file.text();
        let tempsettings;
        console.log(filedata);
        //console.log("before:", plot_data);
        let data;
        [tempsettings, data] = JSON.parse(filedata);
        if (plotdata == undefined) {
            plotdata = [];
        }
        if (data.plotdata != undefined) {
            plotdata = plotdata.concat(modify_data(data.plotdata));
        }
        if (data.measdata != undefined) {
            measdata = modify_data(data.measdata);
            for (const trace of measdata) {
                trace.checked = true;
                trace.mode = tracemode;
            }
        }
        db_data = data.db_data;
        ph_data = data.ph_data;
        settings.title = tempsettings.title;
        settings.title_x = tempsettings.title_x;
        settings.title_y = tempsettings.title_y;
        settings.xaxis_is_log = tempsettings.xaxis_is_log;
        settings.yaxis_is_log = tempsettings.yaxis_is_log;
        //console.log("after:", plot_data);
    }
    let filename = $derived.by(() => {
        measfile == undefined
            ? ""
            : measfile.replace(/.*[\/\\]/, "").replace(/"/, "");
    });
</script>

<button
    use:tooltip={() => msg("show or hide plot settings")}
    onclick={() => (plot_showhide = !plot_showhide)}
    class="button-2">Show/hide</button
>plot#{plot_number}
{#if filename}
    {filename}
{/if}
<button
    use:tooltip={() => msg("make this plot current to push probes")}
    onclick={() => (current_plot = plot_number)}
    class="button-2">Make current</button
>
{#if plot_showhide}
    <button
        use:tooltip={() => msg("save this plot as a CSV file")}
        onclick={() => save_csv()}
        class="button-2">Save as a CSV file</button
    >
    <button
        use:tooltip={() => msg("save this plot as a JSON file")}
        onclick={() => save_json()}
        class="button-2">Save as a JSON file</button
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
                msg("select two or more data columns to display in a graph")}
            >Selection:<input
                bind:value={selection}
                style="border:darkgray solid 1px; width:5%"
            /></label
        >
        <button
            use:tooltip={() => msg("get data from JSON file and plot")}
            onclick={() => read_json(port, wdir, chosen)}
            class="button-1">Plot JSON data</button
        >
        <br />
        <label use:tooltip={() => msg("reverse traces in a graph")}
            >Reverse<input type="checkbox" bind:checked={reverse} /></label
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
            <button
                use:tooltip={() => msg("check all curves")}
                onclick={checkall_measdata}
                class="button-1">check all</button
            >
            <button
                use:tooltip={() => msg("clear all curves")}
                onclick={clear_measdata}
                class="button-1">clear all</button
            >
            <button
                use:tooltip={() => msg("plot all curves")}
                onclick={plot_measured_data_only}
                class="button-1">plot</button
            >
        </div>
    {/if}
    <button
        use:tooltip={() =>
            msg("set probes list (separated by comma) for a current plot")}
        onclick={() => plot_result_clicked(step_precision)}
        class="button-1">Plot with probes:</button
    >
    <input bind:value={probes} style="border:darkgray solid 1px;width:30%" />
    <label
        use:tooltip={() =>
            msg("set probes list (separated by comma) for a current plot")}
        >step precision:
        <input bind:value={step_precision} style="width:5%" />
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
            <input
                bind:value={title}
                style="border:darkgray solid 1px; width: 50%;"
            />
        </label>
        <label use:tooltip={() => msg("X axis title")}
            >X title
            <input
                bind:value={title_x}
                style="border:darkgray solid 1px; width: 15%;"
            />
        </label>
        {#if probes == undefined || !probes.startsWith("frequency")}
            <label use:tooltip={() => msg("Y axis title")}
                >Y title
                <input
                    bind:value={title_y}
                    style="border:darkgray solid 1px; width: 15%;"
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
        <label use:tooltip={() => msg("performance names separated by comma")}>
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
            <textarea
                bind:value={equation}
                style="border:darkgray solid 1px; width: 50%; height: 20px; text-align: bottom"
            />
            <button
                use:tooltip={() =>
                    msg("calculate equations for a current plot")}
                onclick={() => calculate_equation(probes)}
                class="button-1"
            >
                Calculate</button
            >
        </label>
    </div>
    <hr />
{/if}
{#if Array.isArray(calculated_value)}
    <table border="1" style="border-collapse: collapse; font-size:75%">
        <thead>
            <tr>
                {#each performances as perf}
                    <th>{perf}</th>
                {/each}
                {#if calculated_value.length > 1}
                <th>Sweep src/parameter</th>
                {/if}
            </tr>
        </thead>
        <tbody>
            {#if calculated_value.length <= 1}
                {#each calculated_value as vals, i}
                <tr>
                    {#each vals as val}
                        <td>{val}</td>
                    {/each}
                </tr>
                {/each}
            {:else}
               {#each calculated_value[0].map((col, i) => calculated_value.map(row => row[i])) as vals, i}
                <tr>
                    {#each vals as val}
                        <td>{val}</td>
                    {/each}
                    {#if calculated_value.length > 1}
                    <td
                        >{plotdata == undefined
                            ? db_data[i*(probes.split(',').length-1)].name
                            : plotdata[i*(probes.split(',').length-1)].name.replace(/.*@/, '')}</td
                    >
                    {/if}
                </tr>
                {/each}
            {/if}
        </tbody>
    </table>
{/if}

<style>
    label {
        font-family: Arial, "Helvetica Neue", "BIZ UDPGothic", Meiryo,
            "Hiragino Kaku Gothic Pro", sans-serif;
        font-size: 10pt;
    }
</style>
