export let proj = $state({
	ctl_type: 'ltspctl', // ltspctl or ngspctl
	simulator: 'LTspice', // LTspice, Ngspice, (XYCE), (Qucsator)
	schema_editor: 'LTspice', // Xschem, Qucs, EEschema 
    file: '',
    dir: '',
    elements: {},
    models: {},
	results_data: []
});
export let ckt = $state({
    elements: {},
    models: {}
});
export const settings = $state({
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
});