<script lang="ts">
	import Simulate from "./simulate.svelte";
	import ConvertSchematic from "./convertSchematic.svelte";
	import Experiment, { set_trace_names } from "./experiment.svelte";
	import OpenCircuit, { get_control } from "./openCircuit.svelte";
	import SetProbes from "./setProbes.svelte";
	import Bsim3fitting from "./bsim3fitting.svelte";
	import Settings from "./settings/settings.svelte";
	import { tooltip, msg } from "./Utils/tooltip.svelte";
	import PlotResults, {
		measurement_results,
		plot_result,
	} from "./plotResults.svelte";

	import { proj, ckt, settings } from "./shared.svelte.js";

	let { data } = $props();

	export function handleMessage(event) {
		console.log("handleMessage");
		alert(event.detail.text);
		plot_result();
	}

	let current_plot = $state(0); //  = 0;

	/*
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
	*/

	function clear_all_plots() {
		ckt_data = {
			measdata: [],
			plotdata: [],
			db_data: [],
			ph_data: [],
			calculated_value: [],
		};
	}
	let ckt_data = $state({
		measdata: [],
		plotdata: [],
		db_data: [],
		ph_data: [],
		calculated_value: [],
	});
	settings.plot_showhide = [true];
	settings.probes = [""];
	ckt_data.measdata = [[]];
	let variations = $state({});

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
		console.log(
			"measurement group file=",
			$state.snapshot(settings.meas_group),
		);
	}

	function setup_measurement_group() {
		if (ckt == undefined || ckt.elements == undefined) {
			alert("Please read in circuit data first");
			return;
		}
		if (ckt.info == undefined) {
			alert("Simuation results are not available");
			return;
		}
		let file, sel, inv_x, inv_y, meas_elm, elm, val, key;
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
				.replace(/"$/, "")
				.replace("%HOMEPATH%", data.props.home)
				.replace("$HOME", data.props.home);
			settings.selection[current_plot] = sel;
			settings.invert_x[current_plot] = inv_x == "true" ? true : false;
			settings.invert_y[current_plot] = inv_y == "true" ? true : false;
			current_plot = current_plot + 1;
		});
		current_plot = 0;
		console.log("variations=", $state.snapshot(variations), "nvar=", nvar);
	}

	async function plot_measurement_group() {
		// ckt_data, settings
		console.log("settings.measfile", $state.snapshot(settings.measfile));
		//settings.measfile.forEach(async function (measfile, i) {
		//Note: await does not work inside forEach
		let sweep_name;
		for (let i = 0; i < settings.plot_showhide.length; i++) {
			let measfile = settings.measfile[i];
			if (measfile != undefined && measfile != "") {
				ckt_data.measdata[i] = await measurement_results(
					data.props.port,
					proj.dir,
					measfile,
					settings.selection[i],
					settings.reverse[i],
					settings.invert_x[i],
					settings.invert_y[i],
					settings.tracemode[i],
				);
			}
			//ckt_data.measdata[i] = ckt_data.measdata[i];
			let result = plot_result(
				data.props.port,
				proj.dir,
				proj.file,
				settings.probes[i],
				settings.equation[i],
				ckt_data.plotdata[i],
				ckt_data.db_data[i],
				ckt_data.ph_data[i],
				proj.elements,
				settings.step_precision[i],
				"",
			);
			settings.plot_showhide[i] = true;
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
		}
		console.log("ckt_data=", $state.snapshot(ckt_data));
		console.log("sweep_name", sweep_name);
	}

	function clear_measurement_group() {
		settings.meas_group = undefined;
		settings.measfile = [];
		settings.selection = [];
		settings.title = [];
		current_plot = 0;
	}

	function add_plot(ckt_data) {
		settings.plot_showhide.push(true);
		console.log(
			"settings.plot_showhide=",
			$state.snapshot(settings.plot_showhide),
		);
		// console.log('length=', settings.plot_showhide.length);
		current_plot = settings.plot_showhide.length - 1;
		console.log(
			"settings.plot_showhide=",
			$state.snapshot(settings.plot_showhide),
			"current_plot=",
			$state.snapshot(current_plot),
		);
	}

	function duplicate_plot(ckt_data) {
		settings.plot_showhide.push(true);
		let new_plot = settings.plot_showhide.length - 1;
		settings.title[new_plot ]= settings.title[current_plot];
		settings.title_x[new_plot] = settings.title_x[current_plot];
		settings.title_y[new_plot] = settings.title_y[current_plot];
		settings.title_y1[new_plot] = settings.title_y1[current_plot];
		settings.title_y2[new_plot] = settings.title_y2[current_plot];
		settings.yaxis_is_log[new_plot] = settings.yaxis_is_log[current_plot];
		settings.xaxis_is_log[new_plot] = settings.xaxis_is_log[current_plot];
		settings.equation[new_plot] = settings.equation[current_plot];
		settings.performance_names[new_plot] = settings.performance_names[current_plot];
		settings.probes[new_plot] = settings.probes[current_plot];
		ckt_data.plotdata[new_plot] = [...ckt_data.plotdata[current_plot]];
		ckt_data.db_data[new_plot] = [...ckt_data.db_data[current_plot]];
		ckt_data.ph_data[new_plot] = [...ckt_data.ph_data[current_plot]];
		ckt_data.measdata[new_plot] = [...ckt_data.measdata[current_plot]];
		ckt_data.calculated_value[new_plot] = [...ckt_data.calculated_value[current_plot]];
		settings.selection[new_plot] = settings.selection[current_plot];
		settings.reverse[new_plot] = settings.reverse[current_plot];
		settings.invert_x[new_plot] = settings.invert_x[current_plot];
		settings.invert_y[new_plot] = settings.invert_y[current_plot];
		settings.tracemode[new_plot] = settings.tracemode[current_plot];

		current_plot = new_plot;
		console.log(
			"settings.plot_showhide=",
			$state.snapshot(settings.plot_showhide),
		);
		// console.log('length=', settings.plot_showhide.length);
		current_plot = settings.plot_showhide.length - 1;
		console.log(
			"settings.plot_showhide=",
			$state.snapshot(settings.plot_showhide),
			"current_plot=",
			$state.snapshot(current_plot),
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
	}
	let nvar = $state(0);
	let show_meas_group = $state(true);
	console.log("settings=", $state.snapshot(settings));
	let show_flow = $state(data.props.show_flow);
	let show_circuit = $state(!data.props.show_flow);
	let chosen = $state();
</script>

<main>
	<button
		use:tooltip={() => msg("show or hide flow control")}
		onclick={() => {
			if (show_flow) {
				show_flow = false;
				show_circuit = true;
			} else {
				show_flow = true;
				show_circuit = false;
			}
		}}
		class="button-3">show/hide flow control</button
	>
	{#if show_flow}
		<Bsim3fitting
			port={data.props.port}
			bind:ckt_data
			bind:current_plot
			bind:data
			bind:show_flow
			bind:chosen
		/>
	{/if}
	<button
		use:tooltip={() => msg("show or hide circuit")}
		onclick={() => (show_circuit = !show_circuit)}
		class="button-3">show/hide circuit</button
	>
	{#if show_circuit}
		<ConvertSchematic
			port={data.props.port}
			dir={proj.dir}
			bind:editor={proj.schema_editor}
		/>
		<OpenCircuit
			{data}
			bind:probes={settings.probes[current_plot]}
			bind:variations
			bind:nvar
			bind:current_plot
		/>
		<!--	plot_on:open_end={plot_results} -->
		<Settings {data} {ckt} bind:variations />
		<div>
			<Simulate
				port={data.props.port}
				bind:probes={settings.probes[current_plot]}
				bind:variations
				on_sim_end={plot_measurement_group}
				on_sim_start={clear_all_plots}
			/>
			<!-- Testplot / -->
		</div>
	{/if}
	<hr />
	<div>
		<button
			use:tooltip={() => msg("load measurement group")}
			onclick={load_measurement_group_file}
			class="button-2">Load measurement group file</button
		>
		<!-- ConvertSchematic / -->
		{#if settings != undefined && settings.meas_group != undefined}
			<button
				use:tooltip={() =>
					msg("setup simulation for measurement group")}
				onclick={setup_measurement_group}
				class="button-1">Setup</button
			>
			<button
				use:tooltip={() =>
					msg("plot measurement group with simulation")}
				onclick={plot_measurement_group}
				class="button-2">Plot measurement group</button
			>
			<button
				use:tooltip={() => msg("clear measurement group")}
				onclick={clear_measurement_group}
				class="button-1">Clear</button
			>
			<button
				use:tooltip={() =>
					msg("show or hide measurement group files list")}
				onclick={() => (show_meas_group = !show_meas_group)}
				class="button-3">show/hide</button
			>
			{#if show_meas_group}
				{#each settings.meas_group as line}
					<div>{line}</div>
				{/each}
			{/if}
		{/if}
	</div>
	<!-- settings.plot_showhide = {settings.plot_showhide.length} -->
	{#if show_circuit}
		<SetProbes
			bind:probes={settings.probes[current_plot]}
			bind:current_plot
		/>
	{/if}
	<div>
		<button
			use:tooltip={() => msg("add a new plot")}
			onclick={() => add_plot(ckt_data)}
			class="button-2">Add plot</button
		>
		<button
			use:tooltip={() => msg("delete this plot")}
			onclick={delete_plot}
			class="button-2">Delete plot</button
		>
	</div>
	{#each settings.plot_showhide as _, i}
		<PlotResults
			wdir={data.props.wdir}
			port={data.props.port}
			plot_number={i}
			bind:current_plot
			bind:plot_showhide={settings.plot_showhide[i]}
			bind:measfile={settings.measfile[i]}
			bind:step_precision={settings.step_precision[i]}
			bind:title={settings.title[i]}
			bind:title_x={settings.title_x[i]}
			bind:title_y={settings.title_y[i]}
			bind:title_y1={settings.title_y1[i]}
			bind:title_y2={settings.title_y2[i]}
			bind:yaxis_is_log={settings.yaxis_is_log[i]}
			bind:xaxis_is_log={settings.xaxis_is_log[i]}
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
			bind:chosen
		></PlotResults>
	{/each}

	<button
		use:tooltip={() => msg("add a new plot")}
		onclick={() => add_plot(ckt_data)}
		class="button-2">Add plot</button
	>
	<button
		use:tooltip={() => msg("duplicate current plot")}
		onclick={() => duplicate_plot(ckt_data)}
		class="button-2">Duplicate plot</button
	>
	<button
		use:tooltip={() => msg("delete this plot")}
		onclick={delete_plot}
		class="button-2">Delete plot</button
	>
	{#if current_plot != undefined && settings.equation[current_plot] != undefined}
		<Experiment
			port={data.props.port}
			bind:probes={settings.probes[current_plot]}
			bind:equation={settings.equation[current_plot]}
			on_sim_end={plot_measurement_group}
			on_sim_start={clear_all_plots}
		/>
	{/if}
</main>
<svelte:head>
	<link
		rel="stylesheet"
		href="https://unpkg.com/tippy.js@6.3.2/dist/tippy.css"
	/>
</svelte:head>

<style>
	.sample {
		display: flex;
		flex-wrap: wrap;
		/* border: green solid 5px; */
		height: 200px;
		/* background:yellow; */
		overflow: scroll;
	}
</style>
