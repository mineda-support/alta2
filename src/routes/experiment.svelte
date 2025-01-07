<script module>
	export function set_trace_names(res2, probes, elements, step_precision) {
		const plotdata = res2.traces;
		const db_data = res2.db;
		const ph_data = res2.phase;
		let sweep_name;
		//console.log('probes in set_trace_names=', probes);
		if (probes != null && probes.startsWith("frequency")) {
			sweep_name = set_trace_names2(db_data, elements, step_precision);
			sweep_name = set_trace_names2(ph_data, elements, step_precision);
			//console.log("db_data in set_trace_names=", db_data);
		} else {
			sweep_name = set_trace_names2(plotdata, elements, step_precision);
		}
		return [plotdata, db_data, ph_data, sweep_name];
	}

	function set_trace_names2(plotdata, elements, step_precision) {
		let sweep_name, src_values;
		console.log("plotdata in set_trace_names:", plotdata);
		for (const [ckt_name, elms] of Object.entries(elements)) {
			for (const [elm, props] of Object.entries(elms)) {
				//console.log([elm, props]);
				if (elm == "step" || elm == "dc") {
					[sweep_name, src_values] = parse_step_command(
						props.replace(
							/\.dc +\S+ \S+ \S+ \S+ +/,
							".step param ",
						),
						/* props could be like '.dc v3 0 3 0.01 V2 0 3 0.5' */
						step_precision,
					);
					src_values.forEach(function (src_value, index) {
						plotdata[index].name = src_value;
					});
					return sweep_name;
				}
			}
		}
	}
	function eng2f(str) {
		const s = str.toLowerCase();
		let i;
		let e;
		if ((i = s.indexOf("t")) != -1) {
			e = 1.0e12;
		} else if ((i = s.indexOf("g")) != -1) {
			e = 1.0e9;
		} else if ((i = s.indexOf("meg")) != -1) {
			e = 1.0e6;
		} else if ((i = s.indexOf("k")) != -1) {
			e = 1.0e3;
		} else if ((i = s.indexOf("f")) != -1) {
			e = 1.0e-15;
		} else if ((i = s.indexOf("p")) != -1) {
			e = 1.0e-12;
		} else if ((i = s.indexOf("n")) != -1) {
			e = 1.0e-9;
		} else if ((i = s.indexOf("u")) != -1) {
			e = 1.0e-6;
		} else if ((i = s.indexOf("m")) != -1) {
			e = 1.0e-3;
		} else {
			return Number(s);
		}
		//console.log("i=", i, "e=", e);
		//console.log(s.substring(0, i), Number(s.substring(0, i)));
		return Number(s.substring(0, i)) * e;
	}

	function parse_step_command(props, precision) {
		// like '.step param ccap 0.2p 2p 0.5p'
		const items = props.split(/ +/);
		const name = items[2];
		const start = eng2f(items[3]);
		const stop = eng2f(items[4]);
		const step = eng2f(items[5]);
		//console.log("step=", [name, start, stop, step]);
		let src_values = [];
		for (let v = start; v < stop; v = v + step) {
			console.log("precision=", precision);
			src_values.push(`${name}=${v.toPrecision(precision)}`);
		}
		if (stop > start + step * (src_values.length - 1)) {
			src_values.push(`${name}=${stop.toPrecision(precision)}`);
		}
		console.log("src_values in parse_step_command=", src_values);
		return [name, src_values];
	}
</script>

<script lang="ts">
	import Plot from "svelte-plotly.js";
	import { update_elements, update_models } from "./simulate.svelte";
	import SweepSource from "./Utils/sweep_source.svelte";
	import ResultsPlot from "./Utils/results_plot.svelte";
	import { tooltip, msg } from "./Utils/tooltip.svelte";
	import { proj, ckt, settings } from "./shared.svelte.js";
	function get_sweep_values(plotdata) {
		let values = [];
		let sweep, value;
		console.log("plotdata in get_sweep_values=", plotdata);
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

	async function submit_program(program, dir, file) {
		const encoded_params = `dir=${encodeURIComponent(
			dir,
		)}&file=${encodeURIComponent(file)}`;
		// console.log(`program to send: ${program}`);
		const res = await fetch(
			`http://localhost:${port}/api/ltspctl/execute?${encoded_params}`,
			{
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: JSON.stringify({ program: program }),
			},
		);
		plot_data = await res.json();
		console.log(plot_data);
	}
	let plot_data = $state();
	let sweep_name = $state();

	let {
		port,
		probes = $bindable(),
		equation = $bindable(),
		on_sim_start,
		on_sim_end,
	} = $props();

	function postprocess(settings) {
		eval(settings.postprocess);
	}
	let plot_data2 = $state();
	// settings.result_number = 0;
	proj.results_data[settings.result_number] = {};
	function add_experiment() {
		settings.result_number = settings.result_number + 1;
	}
	function clear_experiment() {
		if (settings.result_number > 0) {
			settings.result_number = settings.result_number - 1;
		}
	}
	function execute_script(script, dir, settings, elements) {
		eval(script);
	}

	async function goLTspice2(ckt) {
		console.log(`openLTspice dir='${proj.dir}' file='${proj.file}'`);
		update_elements(proj.dir, ckt, proj.elements);
		console.log("equation=", equation);
		let encoded_params = `dir=${encodeURIComponent(
			proj.dir,
		)}&file=${encodeURIComponent(proj.file)}&probes=${encodeURIComponent(
			probes,
		)}&equation=${encodeURIComponent(equation)}`;
		const models_update = update_models(ckt, proj.models);
		if (models_update != {}) {
			encoded_params =
				encoded_params +
				`&models_update=${encodeURIComponent(JSON.stringify(models_update))}`;
		}
		// dispatch("sim_start", { text: "LTspice simulation started!" });
		let response = await fetch(
			`http://localhost:${port}/api/ltspctl/simulate?${encoded_params}`,
			{},
		);
		let res2 = await response.json();
		console.log("res2=", res2);
		// plotdata = res2.traces;
		let plotdata, db_data, ph_data;
		[plotdata, db_data, ph_data, sweep_name] = set_trace_names(
			res2,
			probes,
			proj.elements,
			settings.step_precision[settings.result_number],
		);
		//dispatch("sim_end", { text: "LTspice simulation ended!" });
		// plotdata = get_results();
		const calculated_value = await res2.calculated_value;
		return [calculated_value, plotdata, db_data, ph_data, sweep_name];
	}

	function create_updates(keep, var_name, par_name, value) {
		if (var_name.match(/^par/)) {
			return [
				`${var_name}: '${keep.replace(/(\.par\S+ *\S+ *= *)(\S+)/, "$1" + value)}'`,
			];
		} else if (var_name.match(/^M/)) {
			let rex = new RegExp(`${par_name} *= *(\\S+)`);
			return [
				`${var_name}: ` + keep.replace(rex, `${par_name}=${value}`),
			];
		} else {
			return [`${var_name}: ${value}`];
		}
	}

	function updates_plus(value, src, par_name, src_plus) {
		let target, var_name;
		console.log("src in updates_plus=", src);
		[target, var_name] = src.split(":");
		let updates = create_updates(
			proj.elements[target][var_name],
			var_name,
			par_name,
			value,
		);
		if (src_plus == undefined) {
			return [updates, target];
		}
		for (const plus of src_plus) {
			[target, var_name, par_name] = plus.split(":");
			if (proj.elements[target] == undefined) {
				alert(`${target} is not this circuit`);
				return;
			}
			console.log("plus=", plus);
			console.log(proj.elements);
			updates = updates.concat(
				create_updates(
					proj.elements[target][var_name],
					var_name,
					par_name,
					value,
				),
			);
		}
		return [updates, target];
	}

	let performances = $derived(
		settings.performance_names[settings.plot_number]
			.split(",")
			.map((a) => a.trim()),
	);

	async function go_experiments(dir, settings, elements) {
		proj.results_data = [];
        proj.results_data[0] = {};
		if (ckt == undefined) {
			alert("Please read-in the circuit before experiment");
		}
		if (settings.src == undefined || settings.src_values[0] == undefined) {
			alert("ERROR: src is not set");
			return;
		}
		let updates, target;
		for (const value2 of settings.src_values[0]) {
			//src, par_name, src_plus) {
			[updates, target] = updates_plus(
				value2,
				settings.src[0],
				settings.par_name[0],
				settings.src_plus[0],
			);
			const trace_name =
				settings.src[0].replace(/^.*:/, "") + ":" + value2;
			//plot_trace.name = trace_name;
			//result_trace.name = trace_name;
			//console.log("updates=", updates, `on ${dir}${target}.asc`);
			await update_elms(proj.dir, target + ".asc", updates);
			// dispatch("sim_start", { text: "LTspice simulation started!" });
			on_sim_start("LTspice simulation started!");
			let calculated_value, plotdata, db_data, ph_data;
			[calculated_value, plotdata, db_data, ph_data, sweep_name] =
				await goLTspice2(ckt);
			performances.forEach(function (perf, index) {
				if (proj.results_data[0][perf] == undefined) {
					proj.results_data[0][perf] = [];
				}
				if (Array.isArray(calculated_value[0])) {
					let result = {
						x: get_sweep_values(
							plotdata != undefined ? plotdata : db_data,
						),
						y: get_performance(calculated_value, index),
						name: trace_name,
					};
					console.log("result=", result);
					proj.results_data[0][perf].push(result);
				} else {
					proj.results_data[0][perf].push(undefined);
				}
			});
			on_sim_end("LTspice simulation ended!");
			performances.forEach((perf) => {
				console.log(`${perf}:`, $state.snapshot(proj.results_data[0][perf]));
			});
			//plot_trace.y = gb;
			//result_trace.y = pm;
			//plot_data.push({ ...plot_trace });
			//plot_data2.push({ ...result_trace });
		}
		console.log("proj.results_data=", $state.snapshot(proj.results_data));
		console.log("proj.results_data[0]=", proj.results_data[0]);
	}
	// plot_data = [{x:[1,2,3,4], y:[1,2,4,3]}];

	function preview_experiments(dir, settings, elements) {
		if (settings.src == undefined || settings.src_values[0] == undefined) {
			alert("ERROR: src is not set");
			return;
		}
		let updates, target;
		if (settings.src_plus[0] == undefined) {
			settings.src_plus[0] = [];
		}
		console.log("probes=", probes);
		console.log("equation=", equation);
		console.log("src[0]=", settings.src[0]);
		console.log("src_plus[0]=", $state.snapshot(settings.src_plus[0]));
		console.log("src_values[0]=", $state.snapshot(settings.src_values[0]));
		//settings.sweep_title = settings.src[0];
		console.log("sweep_title=", settings.sweep_title[0]);
		//settings.result_title = [];
		console.log("result_title=", settings.result_title[0]);
		let preview_table = `count: ${settings.src[0]} ${settings.src_plus[0].join(" ")}\n`;
		let count = 0;
		for (const value2 of settings.src_values[0]) {
			//src, par_name, src_plus) {
			[updates, target] = updates_plus(
				value2,
				settings.src[0],
				settings.par_name[0],
				settings.src_plus[0],
			);
			const trace_name =
				settings.src[0].replace(/^.*:/, "") + ":" + value2;
			//plot_trace.name = trace_name;
			//result_trace.name = trace_name;
			console.log("updates=", updates, `on ${dir}${target}.asc`);
			//await update_elms(dir, target + ".asc", updates);
			//dispatch("sim_start", { text: "LTspice simulation started!" });
			count = count + 1;
			preview_table = preview_table + `${count}: ${value2}\n`;
			//let calculated_value, plotdata, db_data, ph_data;
			//[calculated_value, plotdata, db_data, ph_data] = await goLTspice2(ckt);
			//dispatch("sim_end", { text: "LTspice simulation ended!" });
		}
		let blob = new Blob([preview_table], { type: "text/plain" });
		const link = document.createElement("a");
		link.href = URL.createObjectURL(blob);
		link.download = "experiment_preview.txt";
		link.click();
	}

	function clear_experiments() {
		proj.results_data[settings.result_number] = undefined;
	}

	async function save_experiments() {
		console.log("proj.results_data =", $state.snapshot(proj.results_data));
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
		const blob = JSON.stringify([settings, proj.results_data]);
		const handle = await window.showSaveFilePicker(saveFileOptions);
		const ws = await handle.createWritable();
		await ws.write(blob);
		await ws.close();
	}

	async function load_experiments() {
		const pickerOpts = {
			types: [
				{ description: "JSON(.json)", accept: { "json/*": [".json"] } },
			],
			multiple: false,
		};
		let fileHandle;
		[fileHandle] = await window.showOpenFilePicker(pickerOpts);
		const file = await fileHandle.getFile();
		/* const reader = new FileReader();
		reader.readAsText(file, 'UTF-8');
		let filedata;
		reader.onload = (event) => {
			filedata = (event.target.result);
		}*/
		let filedata = await file.text();
		let tempsettings;
		console.log(filedata);
		//console.log("before:", plot_data);
		[tempsettings, proj.results_data] = JSON.parse(filedata);
		settings.result_title = tempsettings.result_title;
		settings.sweep_title = tempsettings.sweep_title;
		//console.log("after:", plot_data);
	}

	async function update_elms(dir, target, update_elms) {
		console.log("let me update ", target, " with:", update_elms);
		update_elms = encodeURIComponent(`{${update_elms}}`);
		let encoded_params = `dir=${encodeURIComponent(
			dir,
		)}&file=${encodeURIComponent(target)}`;
		const my_sleep = (ms) =>
			new Promise((resolve) => setTimeout(resolve, ms));
		await my_sleep(1000);
		const command = `http://localhost:${port}/api/ltspctl/update?${encoded_params}&updates=${update_elms}`;
		console.log(command);
		let response = await fetch(command, {});
		let ckt = await response.json(); // ckt = {elements}
		console.log("ckt=", ckt);
	}

	function indicator(i) {
		i = Math.abs(i);
		var cent = i % 100;
		if (cent >= 10 && cent <= 20) return "th";
		var dec = i % 10;
		if (dec === 1) return "st";
		if (dec === 2) return "nd";
		if (dec === 3) return "rd";
		return "th";
	}
	console.log("settings=", $state.snapshot(settings));
	settings.result_number = 0;
	settings.src = Array(0);
	settings.par_name = Array(0);
	settings.src_values = Array(0);
	settings.src_plus = Array(0);
	settings.sweep_type = Array(0);
	settings.start_lin_val = Array(0);
	settings.stop_lin_val = Array(0);
	settings.lin_incr = Array(0);
	settings.source_value = Array(0);
	settings.start_dec_val = Array(0);
	settings.stop_dec_val = Array(0);
	settings.dec_points = Array(0);
	settings.src_precision = Array(1);
	settings.src_precision[0] = 3;
</script>

{#if proj.results_data != undefined && proj.results_data[0] != undefined}
	{#each Object.entries(proj.results_data[0]) as [performance, plot_data]}
		<ResultsPlot
			{plot_data}
			title={performance}
			{performance}
			{sweep_name}
		/>
	{/each}
{/if}

<div><p>Make Experiments</p></div>
{#each Array(settings.result_number + 1) as _, i}
	<SweepSource
		source_title="{i + 1}{`${indicator(i + 1)} source`}"
		bind:src={settings.src[i]}
		bind:src_precision={settings.src_precision[i]}
		bind:par_name={settings.par_name[i]}
		bind:src_values={settings.src_values[i]}
		bind:src_plus={settings.src_plus[i]}
		bind:sweep_type={settings.sweep_type[i]}
		bind:start_lin_val={settings.start_lin_val[i]}
		bind:stop_lin_val={settings.stop_lin_val[i]}
		bind:lin_incr={settings.lin_incr[i]}
		bind:start_dec_val={settings.start_dec_val[i]}
		bind:stop_dec_val={settings.stop_dec_val[i]}
		bind:dec_points={settings.dec_points[i]}
		bind:start_oct_val={settings.start_dec_val[i]}
		bind:stop_oct_val={settings.stop_dec_val[i]}
		bind:oct_points={settings.dec_points[i]}
		elements={proj.elements}
	></SweepSource>
{/each}
<label>
	<button
		use:tooltip={() => msg("add new source parameter to sweep")}
		onclick={add_experiment}
		class="button-2">Add experiment</button
	>
</label>
<label>
	<button
		use:tooltip={() => msg("delete an added source parameter")}
		onclick={clear_experiment}
		class="button-1">Clear experiment</button
	>
</label>

<div>
	<label>
		<button
			use:tooltip={() => msg("dry run a sweep experiment")}
			onclick={() =>
				preview_experiments(proj.dir, settings, proj.elements)}
			class="button-1">Dry run</button
		>
	</label>
	<label>
		<button
			use:tooltip={() => msg("execute a sweep experiment")}
			onclick={() => go_experiments(proj.dir, settings, proj.elements)}
			class="button-1">Go</button
		>
	</label>
	<label>
		<button
			use:tooltip={() => msg("clear all experiments")}
			onclick={clear_experiments}
			class="button-1">Clear</button
		>
	</label>
	<label>
		<button
			use:tooltip={() => msg("save experiment")}
			onclick={save_experiments}
			class="button-1">Save</button
		>
	</label>
	<label>
		<button
			use:tooltip={() => msg("load experiment")}
			onclick={load_experiments}
			class="button-1">Load</button
		>
	</label>
</div>

{#if plot_data !== undefined}
	<Plot
		data={plot_data}
		layout={{
			title: settings.result_title,
			xaxis: {
				title: settings.sweep_title,
				autorange: "true",
				linewidth: 1,
				mirror: true,
			},
			yaxis: {
				title: "Gain Bandwidth product",
				autorange: "true",
				linewidth: 1,
				mirror: true,
			},
		}}
		fillParent="width"
		debounce={250}
	/>
{/if}
<!-- div>
	<label>
		<button on:click={postprocess(settings)} class="button-1">
			Postprocess</button
		>
		<textarea
			bind:value={settings.postprocess}
			style="border:darkgray solid 1px; height: 200px; 
width: 90%;"
		/>
	</label>
</div -->
{#if plot_data2 !== undefined}
	<Plot
		data={plot_data2}
		layout={{
			title: settings.result_title,
			xaxis: {
				title: settings.sweep_title,
				autorange: "true",
				linewidth: 1,
				mirror: true,
			},
			yaxis: {
				title: "Phase Margin",
				autorange: "true",
				linewidth: 1,
				mirror: true,
			},
		}}
		fillParent="width"
		debounce={250}
	/>
{/if}

<style>
	.p {
		font-family: Arial, "Helvetica Neue", "BIZ UDPGothic", Meiryo,
			"Hiragino Kaku Gothic Pro", sans-serif;
		font-size: 8pt;
	}
</style>
