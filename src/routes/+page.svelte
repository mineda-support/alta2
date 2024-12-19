<script>
	import { goto } from "$app/navigation";
	import { json } from "@sveltejs/kit";
	// import Testplot, {handleMessage} from "./test_plot.svelte";
	// import { plot_result } from "./test_plot.svelte";
	import Simulate from "./simulate.svelte";
	import ConvertSchematic from "./convertSchematic.svelte";
	import Experiment, { set_trace_names } from "./experiment.svelte";
	// import OpenLTspice, {update_elements} from "./openLTspice.svelte";
	import OpenLTspice, { get_control } from "./openLTspice.svelte";
	import Settings from "./settings.svelte";
	// import Plot from "svelte-plotly.js";
	import PlotResults, {
		measurement_results,
		plot_result,
	} from "./plotResults.svelte";

	import {
		ckt_name,
		dir_name,
		ckt_store,
		elements_store,
		settings_store,
		//models_store,
	} from "./stores.js";
	//import { stringify } from "postcss";
	//import { A } from "plotly.js-dist";
	let file;
	let dir;
	let ckt;
	let elements;
	//let models;

	ckt_name.subscribe((value) => {
		file = value;
	});
	dir_name.subscribe((value) => {
		dir = value;
	});
	ckt_store.subscribe((value) => {
		ckt = value;
	});
	elements_store.subscribe((value) => {
		elements = value;
	});
	elements_store.set({});
	//models_store.subscribe((value) => {
	//	models = value;
	//});
	//models_store.set({});
	let settings;
	settings_store.subscribe((value) => {
		settings = value;
	});
	ckt_store.set(undefined);

	export let data;

	let results_data = [];
	results_data[0] = [];

	export function handleMessage(event) {
		console.log("handleMessage");
		alert(event.detail.text);
		plot_result();
	}

	let calculated_value;
	// $: calculated_value = calculated_value;
	$: results_data = results_data;
	let current_plot; //  = 0;
	function plot_results() {
		if (variations == {}) {
			return;
		}
		let vals;
		for (const [ckt_name, elms] of Object.entries(elements)) {
			for (const [elm, props] of Object.entries(elms)) {
				if (elm.match(/#$/) && (vals = variations[elm])) {
					vals.forEach((val) => {
						current_plot = current_plot + 1;
					});
					return;
				}
			}
		}
	}

	function clear_all_plots() {
		ckt_data = {
			measdata: [],
			plotdata: [],
			db_data: [],
			ph_data: [],
			calculated_value: [],
		};
	}

	settings = {
		plot_number: 0,
		plot_showhide: [],
		meas_group: undefined,
		measfile: [],
		step_precision: [],
		title: [],
		title_x: [],
		title_y: [],
		title_y1: [],
		title_y2: [],
		yaxis_is_log: [],
		xaxis_is_log: [],
		equation: [],
		performance_names: [],
		probes: [],
		selection: [],
		reverse: [],
		invert_x: [],
		invert_y: [],
		tracemode: [],
		par_name: [],
		sweep_type: [],
		start_lin_val: [],
		stop_lin_val: [],
		lin_incr: [],
		src_value: [],
		start_dec_val: [],
		stop_dec_val: [],
		dec_points: [],
		start_oct_val: [],
		stop_oct_val: [],
		oct_points: [],
		src_title: [],
		src_precision: [],

		src: [],
		src_plus: [],
		src_values: [],
		sweep_title: [],
		result_title: [],
	};
	let ckt_data = {
		measdata: [],
		plotdata: [],
		db_data: [],
		ph_data: [],
		calculated_value: [],
	};
	settings.plot_showhide = [true];
	settings.probes = [""];
	ckt_data.measdata = [[]];
	let variations = {};

	async function load_measurement_group_file() {
		if (ckt == undefined || ckt.elements == undefined) {
			alert("Please read in circuit data first");
			return;
		}
		const pickerOpts = {
			types: [
				{ description: "CSV(.csv)", accept: { "csv/*": [".csv"] } },
			],
			multiple: false,
		};
		let fileHandle;
		[fileHandle] = await window.showOpenFilePicker(pickerOpts);
		const file = await fileHandle.getFile();
		const decoder = new TextDecoder("sjis");
		const filedata = await file.arrayBuffer(); //text()
		settings.meas_group = decoder
			.decode(new Uint8Array(filedata))
			.split(/\n/);
		//measgrp_filedata = await file.arrayBuffer();
		console.log("measurement group file=", settings.meas_group);
	}

	function setup_measurement_group() {
		if (ckt == undefined || ckt.elements == undefined) {
			alert("Please read in circuit data first");
		}
		let line, file, sel, inv_x, inv_y, meas_elm, elm, val, key;
		current_plot = 0;
		settings.meas_group.forEach(function (line, index) {
			[file, sel, inv_x, inv_y, meas_elm, val] = line
				.split(",")
				.map((a) => a.trim());
			console.log("file=", file, "sel=", sel);
			let result = /\((.*)\)/.exec(meas_elm);
			elm = result[1];
			key = Object.keys(ckt.elements)[0] + ":" + elm;
			if (variations[key] == undefined) {
				variations[key] = [];
			}
			variations[key][index] = val;
			nvar = index + 1;
			settings.probes[current_plot] =
				ckt.info[0] +
				", " +
				meas_elm.replace(elm, elm + "#" + (index + 1));
			settings.plot_showhide[current_plot] = true;
			settings.title[current_plot] = val;
			settings.measfile[current_plot] = file
				.replace(/^"/, "")
				.replace(/"$/, "");
			settings.selection[current_plot] = sel;
			settings.invert_x[current_plot] = inv_x == "true" ? true : false;
			settings.invert_y[current_plot] = inv_y == "true" ? true : false;
			current_plot = current_plot + 1;
		});
		settings = settings;
		current_plot = 0;
		console.log("variations=", variations, "nvar=", nvar);
	}

	async function plot_measurement_group() { // ckt_data, settings
		console.log("settings.measfile", settings.measfile);
		//settings.measfile.forEach(async function (measfile, i) {
        //Note: await does not work inside forEach
		let sweep_name;
		for (let i = 0; i < settings.measfile.length; i++) {
			let measfile = settings.measfile[i];
			ckt_data.measdata[i] = await measurement_results(
				measfile,
				settings.selection[i],
				settings.reverse[i],
				settings.invert_x[i],
				settings.invert_y[i],
				settings.tracemode[i]
			);
			//ckt_data.measdata[i] = ckt_data.measdata[i];
			let result = plot_result(
				dir,
				file,
				settings.probes[i],
				settings.equation[i],
				ckt_data.plotdata[i],
				ckt_data.db_data[i],
				ckt_data.ph_data[i],
				elements,
				settings.step_precision[i],
				"",
			);
			settings.plot_showhide[i] = false;
			[
				ckt_data.plotdata[i],
				ckt_data.db_data[i],
				ckt_data.ph_data[i],
				sweep_name,
			] = await result;
			// ckt_data.plotdata[i] = ckt_data.plotdata[i];
			// *const my_sleep = (ms) =>  ### sleep is useless
			//	new Promise((resolve) => setTimeout(resolve, ms));
			//await my_sleep(3000); 
		};
        console.log('ckt_data=', ckt_data);
		console.log('sweep_name', sweep_name);
		settings = settings;
		ckt_data = ckt_data;
	}

	function clear_measurement_group() {
		settings.meas_group = undefined;
		settings.meas_file = [];
		settings.selection = [];
		settings.title = [];
		current_plot = 0;
	}

	function add_plot() {
		settings.plot_showhide.push(true);
		console.log("settings.plot_showhide=", settings.plot_showhide);
		// console.log('length=', settings.plot_showhide.length);
		current_plot = settings.plot_showhide.length - 1;
		settings = settings;
		console.log(
			"settings.plot_showhide=",
			settings.plot_showhide,
			"current_plot=",
			current_plot,
		);
	}

	function delete_plot() {
		console.log("current_plot to delete=", current_plot);
		for (const [obj] of Object.entries(settings)) {
			// console.log(`settings.${obj}=`, settings[obj]);
			if (Array.isArray(settings[obj])) {
				settings[obj].splice(current_plot, 1);
			}
		}
		settings = settings;
	}
	let nvar = 0;
</script>

<ConvertSchematic {dir} />
<OpenLTspice
	{data}
	bind:probes={settings.probes[current_plot]}
	bind:variations
	bind:nvar
	bind:current_plot
/>
<!--	plot_on:open_end={plot_results} -->
<Settings {data} {ckt} bind:variations bind:settings />
<div>
	<Simulate
		bind:probes={settings.probes[current_plot]}
		bind:variations
		on:sim_end={plot_results}
		on:sim_start={clear_all_plots}
	/>
	<!-- Testplot / -->
</div>
<hr />
<div>
	<button on:click={load_measurement_group_file} class="button-2"
		>Load measurement group file</button
	>
	<!-- ConvertSchematic / -->
	{#if settings.meas_group != undefined}
		<button on:click={setup_measurement_group} class="button-1"
			>Setup</button
		>
		<button
			on:click={plot_measurement_group}
			class="button-2">Plot measurement group</button
		>
		<button on:click={clear_measurement_group} class="button-1"
			>Clear</button
		>
		{#each settings.meas_group as line}
			<div>{line}</div>
		{/each}
	{/if}
</div>
{#each settings.plot_showhide as _, i}
	<PlotResults
		bind:current_plot
		plot_number={i}
		bind:plot_showhide={settings.plot_showhide[i]}
		bind:results_data
		bind:dir
		bind:file
		bind:elements
		bind:measfile={settings.measfile[i]}
		bind:step_precision={settings.step_precision[i]}
		bind:title={settings.title[i]}
		bind:title_x={settings.title_x[i]}
		bind:title_y={settings.title_y[i]}
		bind:title_y1={settings.title_y1[i]}
		bind:title_y2={settings.title_y2[i]}
		bind:yaxis_is_log={settings.yaxis_is_log}
		bind:xaxis_is_log={settings.xaxis_is_log}
		bind:equation={settings.equation[i]}
		bind:performance_names={settings.performance_names[i]}
		bind:probes={settings.probes[i]}
		bind:plotdata={ckt_data.plotdata[i]}
		bind:db_data={ckt_data.db_data[i]}
		bind:ph_data={ckt_data.ph_data[i]}
		bind:measdata={ckt_data.measdata[i]}
		bind:calculated_value={ckt_data.calculated_value[i]}
		bind:selection={settings.selection[i]}
		bind:reverse={settings.reverse[i]}
		bind:invert_x={settings.invert_x[i]}
		bind:invert_y={settings.invert_y[i]}
		bind:tracemode={settings.tracemode[i]}
	></PlotResults>
{/each}

<button on:click={add_plot} class="button-2">Add plot</button>
<button on:click={delete_plot} class="button-2">Delete plot</button>

{#if settings.equation[current_plot] != undefined}
	<Experiment
		bind:settings
		bind:results_data
		{elements}
		bind:probes={settings.probes[current_plot]}
		bind:equation={settings.equation[current_plot]}
		bind:performance_names={settings.performance_names[current_plot]}
	/>
{/if}
