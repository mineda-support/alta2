<script context="module">
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
						props.replace(/\.dc +\S+ \S+ \S+ \S+ +/, '.step param '),
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
			console.log('precision=', precision);
			src_values.push(`${name}=${v.toPrecision(precision)}`);
		}
		if (stop > start + step * (src_values.length - 1)) {
			src_values.push(`${name}=${stop.toPrecision(precision)}`);
		}
		console.log("src_values in parse_step_command=", src_values);
		return [name, src_values];
	}
</script>

<script>
	import Plot from "svelte-plotly.js";
	import { update_elements, update_models } from "./simulate.svelte";
	import SweepSource from "./utils/sweep_source.svelte";
	import ResultsPlot from "./utils/results_plot.svelte";
	import {
		ckt_name,
		dir_name,
		ckt_store,
		models_store,
	} from "./stores.js";
	import { bindAll, dot$1, number, R, update } from "plotly.js-dist";
	let ckt;
	let file, dir;
	let models;

	export let settings;
	export let results_data;
	export let elements;
	export let probes;
	export let equation; 
	export let performance_names;

	ckt_name.subscribe((value) => {
		file = value;
	});
	dir_name.subscribe((value) => {
		dir = value;
	});
	ckt_store.subscribe((value) => {
		ckt = value;
	});
    models_store.subscribe((value) => {
        models = value;
    });

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
			`http://localhost:9292/api/ltspctl/execute?${encoded_params}`,
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
	let plot_data;
	let sweep_name;
	$: settings.sweep_name = sweep_name;
	let src1;
	$: settings.src1 = src1;

	import { createEventDispatcher } from "svelte";
	const dispatch = createEventDispatcher();

	function postprocess(settings) {
		eval(settings.postprocess);
	}
	let plot_data2;
	settings.result_number = 0;
	results_data[settings.result_number] = {};
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

	async function goLTspice2(ckt) {
		console.log(`openLTspice dir='${dir}' file='${file}'`);
		update_elements(dir, ckt, elements);
		/* dispatch("elm_update", { text: "Update elements" });
		const my_sleep = (ms) =>
            new Promise((resolve) => setTimeout(resolve, ms));
        await my_sleep(3000); */
		console.log("equation=", equation);
		let encoded_params = `dir=${encodeURIComponent(
			dir,
		)}&file=${encodeURIComponent(file)}&probes=${encodeURIComponent(
			probes,
		)}&equation=${encodeURIComponent(equation)}`;
		const models_update = update_models(ckt, models);
        if (models_update != {}) {
            encoded_params =
                encoded_params +
                `&models_update=${encodeURIComponent(JSON.stringify(models_update))}`;
        }
		// dispatch("sim_start", { text: "LTspice simulation started!" });
		let response = await fetch(
			`http://localhost:9292/api/ltspctl/simulate?${encoded_params}`,
			{},
		);
		let res2 = await response.json();
		console.log("res2=", res2);
		// plotdata = res2.traces;
		let plotdata, db_data, ph_data;
		[plotdata, db_data, ph_data, sweep_name] = set_trace_names(
			res2,
			probes,
			elements,
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
			elements[target][var_name],
			var_name,
			par_name,
			value,
		);
		if (src_plus == undefined) {
			return [updates, target];
		}
		for (const plus of src_plus) {
			[target, var_name, par_name] = plus.split(":");
			if (elements[target] == undefined) {
				alert(`${target} is not this circuit`);
				return;
			}
			console.log("plus=", plus);
			console.log(elements);
			updates = updates.concat(
				create_updates(
					elements[target][var_name],
					var_name,
					par_name,
					value,
				),
			);
		}
		return [updates, target];
	}
	// console.log("updates=", updates, `on ${dir}${target}.asc`);
	// await update_elms(dir, target+'.asc', updates);

	let performances;
	$: {
		let performance_names = settings.performance_names[settings.plot_number];
		if (performance_names != undefined) {
			console.log(`performance_names[${settings.plot_number}]=`, performance_names);
			performances = performance_names.split(",").map((a) => a.trim());
			console.log('performances=', performances);
		}
	}

	async function go_experiments(dir, settings, elements) {
		if (ckt == undefined) {
            alert("Please read-in the circuit before experiment");
        }
		if (settings.src == undefined || settings.src_values[0] == undefined) {
			alert("ERROR: src is not set");
			return;
		}
		let updates, target;
		results_data = [];
		results_data[0] = [];
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
			await update_elms(dir, target + ".asc", updates);

			dispatch("sim_start", { text: "LTspice simulation started!" });
			let calculated_value, plotdata, db_data, ph_data;
			[calculated_value, plotdata, db_data, ph_data, sweep_name] =
				await goLTspice2(ckt);
			performances.forEach(function (perf, index) {
				if (results_data[0][perf] == undefined) {
					results_data[0][perf] = [];
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
					results_data[0][perf].push(result);
				} else {
					results_data[0][perf].push(undefined);
				}
			});
			dispatch("sim_end", { text: "LTspice simulation ended!" });
			performances.forEach((perf) => {
				console.log(`${perf}:`, results_data[0][perf]);
			});
			//plot_trace.y = gb;
			//result_trace.y = pm;
			//plot_data.push({ ...plot_trace });
			//plot_data2.push({ ...result_trace });
			for (let [perf, plotdata] of Object.entries(results_data[0])) {
				plotdata = plotdata;
			}
			results_data = results_data;
		}
		console.log("results_data=", results_data);
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
		console.log("src_plus[0]=", settings.src_plus[0]);
		console.log("src_values[0]=", settings.src_values[0]);
		//settings.sweep_title = settings.src[0];
		console.log("sweep_title=", settings.sweep_title[0]);
		//settings.result_title = [];
		console.log("result_title=", settings.result_title[0]);
		results_data = [];
		results_data[0] = [];
		let preview_table = `count: ${settings.src[0]} ${settings.src_plus[0].join(" ")}}\n`;
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
		results_data[settings.result_number] = undefined;
	}

	async function save_experiments() {
		const blob = JSON.stringify([settings, results_data]);
		const handle = await window.showSaveFilePicker();
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
		[tempsettings, results_data] = JSON.parse(filedata);
		settings.result_title = tempsettings.result_title;
		settings.sweep_title = tempsettings.sweep_title;
		//console.log("after:", plot_data);
	}

	async function go(dir, settings, elements) {
		plot_data = [];
		let plot_trace = { x: [], y: [] };
		plot_data2 = [];
		let result_trace = { x: [], y: [] };
		//alert(settings.src1);
		let var_name;
		let target;
		[target, var_name] = settings.src1.split(":");
		//console.log(target, var_name);
		//const keep = elements[target][var_name];
		settings.sweep_title = settings.src1;
		settings.result_title = file;
		let updates;

		for (const value2 of settings.src2_values) {
			//src, par_name, src_plus) {
			[updates, target] = updates_plus(
				value2,
				settings.src2,
				settings.par_name2,
				settings.src2_plus,
			);
			const trace_name = settings.src2.replace(/^.*:/, "") + ":" + value2;
			plot_trace.name = trace_name;
			result_trace.name = trace_name;
			console.log("updates=", updates, `on ${dir}${target}.asc`);
			await update_elms(dir, target + ".asc", updates);
			let gb = []; // Gain Bandwidth product
			let pm = []; // Phase Margin
			plot_trace.x = [];
			result_trace.x = [];
			for (const value of settings.src1_values) {
				[updates, target] = updates_plus(
					value,
					settings.src1,
					settings.par_name1,
					settings.src1_plus,
				);
				console.log("updates=", updates, `on ${dir}${target}.asc`);
				await update_elms(dir, target + ".asc", updates);

				dispatch("sim_start", { text: "LTspice simulation started!" });
				let calculated_value = await goLTspice2(ckt);
				if (Array.isArray(calculated_value[0])) {
					gb.push(calculated_value[0][0]);
					pm.push(calculated_value[0][1]);
				} else {
					gb.push(undefined);
					pm.push(undefined);
				}
				dispatch("sim_end", { text: "LTspice simulation ended!" });
				plot_trace.x.push(Number(value));
				result_trace.x.push(Number(value));
			}
			console.log("gb=", gb);
			console.log("pm=", pm);
			plot_trace.y = gb;
			result_trace.y = pm;
			plot_data.push({ ...plot_trace });
			plot_data2.push({ ...result_trace });
			/*
			console.log(
					`${var_name}: ${keep.replace(/(\.par\S+ *\S+ *= *)(\S+)/, "$1" + value)}`,
				);
				let updates = [
					`${var_name}: '${keep.replace(/(\.par\S+ *\S+ *= *)(\S+)/, "$1" + value)}'`,
				];
				console.log(updates);
				await update_elms(dir, target + ".asc", updates);
			} else {
				console.log(`${var_name}: ${value}`);
			}
			dispatch("sim_start", { text: "LTspice simulation started!" });
			let calculated_value = await goLTspice2(ckt);
			gb.push(calculated_value[0][0]);
			pm.push(calculated_value[0][1]);
			dispatch("sim_end", { text: "LTspice simulation ended!" });
			plot_data[0].x.push(Number(value));
			plot_data2[0].x.push(Number(value));
*/
		}
		plot_data = plot_data;
		plot_data2 = plot_data2;
		console.log("plot_data=", plot_data);
	}
	// plot_data = [{x:[1,2,3,4], y:[1,2,4,3]}];

	function preview_updates(dir, settings, elements) {
		plot_data = [];
		let var_name;
		let target;
		console.log("probes=", probes);
		console.log("equation=", equation);
		console.log("src1=", settings.src1);
		console.log("src1_plus=", settings.src1_plus);
		console.log("src1_values=", settings.src1_values);
		settings.sweep_title = settings.src1;
		settings.result_title = file;
		console.log("sweep_title=", settings.sweep_title);
		console.log("result_title=", settings.result_title);

		[target, var_name] = settings.src1.split(":");
		// console.log(target, var_name);
		if (
			elements[target] == undefined ||
			elements[target][var_name] == undefined
		) {
			return;
		}
		let plot_trace = { x: [], y: [] };
		let updates;
		let count = 0;
		if (settings.src1_plus == undefined) {
			settings.src1_plus = [];
		}
		if (settings.src2_plus == undefined) {
			settings.src2_plus = [];
		}
		let preview_table = `count: ${settings.src2} ${settings.src2_plus.join(" ")}, ${settings.src1} ${settings.src1_plus.join(" ")}\n`;
		for (const value2 of settings.src2_values) {
			//src, par_name, src_plus) {
			[updates, target] = updates_plus(
				value2,
				settings.src2,
				settings.par_name2,
				settings.src2_plus,
			);
			plot_trace.name = settings.src2 + ":" + value2;
			console.log("plot_trace!!!", count, plot_trace);
			console.log("updates=", updates, `on ${dir}${target}.asc`);
			//preview_table = preview_table + settings.src2 + ':' + value2 + "\n";
			//preview_table = preview_table + `plot_trace.name = ${settings.src2} + ':' + ${value2}\n`;

			for (const value of settings.src1_values) {
				[updates, target] = updates_plus(
					value,
					settings.src1,
					settings.par_name1,
					settings.src1_plus,
				);
				console.log("updates=", updates, `on ${dir}${target}.asc`);
				// await update_elms(dir, target+'.asc', updates);
				count = count + 1;
				preview_table = preview_table + `${count}: ${value2}\n`;
			}
			plot_data.push({ ...plot_trace });
			console.log("plot_trace=", count, plot_trace);
		}
		console.log("plot_data =", plot_data);
		let blob = new Blob([preview_table], { type: "text/plain" });
		const link = document.createElement("a");
		link.href = URL.createObjectURL(blob);
		link.download = "experiment_preview.txt";
		link.click();
	}

	async function update_elms(dir, target, update_elms) {
		console.log("let me update ", target, " with:", update_elms);
		update_elms = encodeURIComponent(`{${update_elms}}`);
		let encoded_params = `dir=${encodeURIComponent(
			dir,
		)}&file=${encodeURIComponent(target)}`;
		const command = `http://localhost:9292/api/ltspctl/update?${encoded_params}&updates=${update_elms}`;
		console.log(command);
		let response = await fetch(command, {});
		let ckt = await response.json(); // ckt = {elements}
		console.log("ckt=", ckt);
	}

	function clear() {
		plot_data = plot_data2 = undefined;
		results_data[settings.result_number] = undefined;
	}

	async function save() {
		const blob = JSON.stringify([settings, plot_data, plot_data2]);
		const handle = await window.showSaveFilePicker();
		const ws = await handle.createWritable();
		await ws.write(blob);
		await ws.close();
	}

	async function load() {
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
		console.log("before:", plot_data);
		[tempsettings, plot_data, plot_data2] = JSON.parse(filedata);
		settings.result_title = tempsettings.result_title;
		settings.sweep_title = tempsettings.sweep_title;
		console.log("after:", plot_data);
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
	settings.src_precision = Array(0);
</script>

<!-- {#if results_data != undefined && results_data[0].length > 0} -->
{#each Object.entries(results_data[0]) as [performance, plot_data]}
	<ResultsPlot {plot_data} title={performance} {performance} {sweep_name} />
{/each}
<!-- {/if} -->
<div>Make Experiments</div>
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
		bind:src_value={settings.source_value[i]}
		bind:start_dec_val={settings.start_dec_val[i]}
		bind:stop_dec_val={settings.stop_dec_val[i]}
		bind:dec_points={settings.dec_points[i]}
		bind:start_oct_val={settings.start_dec_val[i]}
		bind:stop_oct_val={settings.stop_dec_val[i]}
		bind:oct_points={settings.dec_points[i]}
		bind:elements={elements}
	></SweepSource>
{/each}
<label>
	<button on:click={add_experiment} class="button-2">Add experiment</button>
</label>
<label>
	<button on:click={clear_experiment} class="button-1"
		>Clear experiment</button
	>
</label>

<div>
	<label>
		<button
			on:click={preview_experiments(dir, settings, elements)}
			class="button-1">Dry run</button
		>
	</label>
	<label>
		<button
			on:click={go_experiments(dir, settings, elements)}
			class="button-1">Go</button
		>
	</label>
	<label>
		<button on:click={clear_experiments} class="button-1">clear</button>
	</label>
	<label>
		<button on:click={save_experiments} class="button-1">Save</button>
	</label>
	<label>
		<button on:click={load_experiments} class="button-1">Load</button>
	</label>
</div>

<!-- SweepSource
	source_title="1st source"
	bind:src={settings.src1}
	bind:par_name={settings.par_name1}
	bind:src_values={settings.src1_values}
	bind:src_plus={settings.src1_plus}
	bind:sweep_type={settings.sweep_type1}
	bind:start_lin_val={settings.start_lin_val1}
	bind:stop_lin_val={settings.stop_lin_val1}
	bind:lin_incr={settings.lin_incr1}
	bind:src_value={settings.source_value1}
	bind:start_dec_val={settings.start_dec_val1}
	bind:stop_dec_val={settings.stop_dec_val1}
	bind:dec_incr={settings.dec_points1}
	bind:src_precision={settings.src_precision1}
	bind:elements
></SweepSource -->
<!-- SweepSource
	source_title="2nd source"
	bind:src={settings.src2}
	bind:par_name={settings.par_name2}
	bind:src_values={settings.src2_values}
	bind:src_plus={settings.src2_plus}
	bind:sweep_type={settings.sweep_type2}
	bind:start_lin_val={settings.start_lin_val2}
	bind:stop_lin_val={settings.stop_lin_val2}
	bind:lin_incr={settings.lin_incr2}
	bind:src_value={settings.source_value2}
	bind:start_dec_val={settings.start_dec_val2}
	bind:stop_dec_val={settings.stop_dec_val2}
	bind:dec_incr={settings.dec_points2}
	bind:src_precision={settings.src_precision2}
	bind:elements
></SweepSource -->
<!-- div>
	<label>
		<button
			on:click={preview_updates(dir, settings, elements)}
			class="button-1">Dry run</button
		>
	</label>
	<label>
		<button on:click={go(dir, settings, elements)} class="button-1"
			>Go</button
		>
	</label>
	<label>
		<button on:click={clear} class="button-1">clear</button>
	</label>
	<label>
		<button on:click={save} class="button-1">Save</button>
	</label>
	<label>
		<button on:click={load} class="button-1">Load</button>
	</label>
</div -->
<div>
	<!-- label>
		<button
			on:click={execute_script(settings.script, dir, settings, elements)}
			class="button-1"
		>
			Execute below script</button
		>
		<textarea
			bind:value={settings.script}
			style="border:darkgray solid 1px; height: 200px; 
width: 90%;"
		/>
	</label -->
	<!-- label>
		<button
			on:click={submit_program(settings.program, dir, file)}
			class="button-1"
		>
			Submit below program</button
		>
		<textarea
			bind:value={settings.program}
			style="border:darkgray solid 1px; height: 200px; 
width: 90%;"
		/>
	</label -->
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
</style>
